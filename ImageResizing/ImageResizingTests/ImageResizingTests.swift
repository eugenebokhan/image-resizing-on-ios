import XCTest
import UIKit
import Alloy
import MetalPerformanceShaders

class ImageResizingTests: XCTestCase {

    public enum ResizeTechnique: String, CaseIterable {
        case uiKit
        case coreImage
        case coreGraphics
        case imageIO
        case accelerate

        var technique: CGImage.ResizeTechnique {
            switch self {
            case .uiKit: return .uiKit
            case .coreImage: return .coreImage
            case .coreGraphics: return .coreGraphics
            case .imageIO: return .imageIO
            case .accelerate: return .accelerate
            }
        }
    }

    var context: MTLContext!
    var textureDifference: TextureDifferenceHighlight!
    var l2Distance: EuclideanDistance!
    var lanczosScale: MPSImageLanczosScale!

    var sourceImage: CGImage! = nil
    let destinationSize = CGSize(width: 600,
                                 height: 600)
    /// This texture is created by using Lanczos resampling algorithm,
    /// that typically produces better quality for photographs.
    /// It's the best candidate to be used as an expected result in `quality tests`.
    var lanczosScaleResultTexture: MTLTexture!

    override func setUp() {
        do {
            self.context = try .init()
            self.textureDifference = try .init(context: self.context)
            self.l2Distance = try .init(context: self.context)
            self.lanczosScale = .init(device: self.context.device)

            guard let sourceImageURL = Bundle(for: Self.self).url(forResource: "Clown_Fish_1200x1200",
                                                            withExtension: "png"),
                  let sourceImage = try? UIImage(data: .init(contentsOf: sourceImageURL))?.cgImage
            else { throw UIImage.Error.cgImageCreationFailed }
            self.sourceImage = sourceImage

            let sourceTexture = try self.context.texture(from: self.sourceImage)
            let destinationTexureDescriptor = sourceTexture.descriptor
            destinationTexureDescriptor.usage = [.shaderRead, .shaderWrite]
            destinationTexureDescriptor.width = .init(self.destinationSize.width)
            destinationTexureDescriptor.height = .init(self.destinationSize.height)
            self.lanczosScaleResultTexture = try self.context
                                                     .texture(descriptor: destinationTexureDescriptor)

            try self.context.scheduleAndWait { commandBuffer in
                self.lanczosScale.encode(commandBuffer: commandBuffer,
                                         sourceTexture: sourceTexture,
                                         destinationTexture: self.lanczosScaleResultTexture
                )
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Quality

    func testQuality() {
        do {
            try ResizeTechnique.allCases.forEach { resizeTechnique in
                var resizedImage = try self.sourceImage
                                           .resized(to: self.destinationSize,
                                                    with: resizeTechnique.technique)
                /// ImageIO's output image has `premultipliedFirst` alfa info. Need tp change in to `premultipliedLast`.
                if resizeTechnique == .imageIO {
                    resizedImage = try resizedImage.withCangedAlfaInfo(to: .premultipliedLast)
                }

                let resizedTexture = try self.context
                                             .texture(from: resizedImage)

                let differenceTexture = try self.lanczosScaleResultTexture
                                                .matchingTexture()
                let distanceResultBuffer = try self.context
                                                   .buffer(for: Float.self,
                                                           options: .storageModeShared)


                try self.context.scheduleAndWait { commandBuffer in
                    self.l2Distance
                        .encode(textureOne: self.lanczosScaleResultTexture,
                                textureTwo: resizedTexture,
                                resultBuffer: distanceResultBuffer,
                                in: commandBuffer)
                    self.textureDifference
                        .encode(sourceTextureOne: resizedTexture,
                                sourceTextureTwo: self.lanczosScaleResultTexture,
                                destinationTexture: differenceTexture,
                                color: .init(1, 0, 0, 1),
                                threshold: 0.01,
                                in: commandBuffer)
                }

                let distance = distanceResultBuffer.pointer(of: Float.self)?
                                                   .pointee ?? 0
                let distanceAttachment = XCTAttachment(string: "L2 distance: \(distance)")
                distanceAttachment.name = "L2 distance of \(resizeTechnique.rawValue)"
                distanceAttachment.lifetime = .keepAlways
                self.add(distanceAttachment)

                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .prettyPrinted
                let data = try jsonEncoder.encode(differenceTexture.codable())

                let differenceAttachment = XCTAttachment(data: data,
                                                         uniformTypeIdentifier: Self.textureUTI)
                differenceAttachment.name = "Difference of \(resizeTechnique.rawValue)"
                differenceAttachment.lifetime = .keepAlways
                self.add(differenceAttachment)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Perfomance

    func testUIKitPerformance() {
        measure {
            _ = try! self.sourceImage
                         .resized(to: self.destinationSize,
                                  with: .uiKit)
        }
    }

    func testCoreImagePerformance() {
        measure {
            _ = try! self.sourceImage
                         .resized(to: self.destinationSize,
                                  with: .coreImage)
        }
    }

    func testCoreGraphicsPerformance() {
        measure {
            _ = try! self.sourceImage
                         .resized(to: self.destinationSize,
                                  with: .coreGraphics)
        }
    }

    func testImageIOPerformance() {
        measure {
            _ = try! self.sourceImage
                         .resized(to: self.destinationSize,
                                  with: .imageIO)
        }
    }

    func testAcceleratePerformance() {
        measure {
            _ = try! self.sourceImage
                         .resized(to: self.destinationSize,
                                  with: .accelerate)
        }
    }

    private static let textureUTI = "com.eugenebokhan.mtltextureviewer.texture"

}
