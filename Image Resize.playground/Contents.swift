import UIKit

func testImageResize() {
    
    guard let originalImage = UIImage(named: "Clown Fish") else { return }
    
    let newSize = CGSize(width: 600, height: 600)
    
    /// UIKit
    let uiKitMeasurement = measure(originalImage.resize(to: newSize, with: .UIKit))
    log("ResizeTechnique: UIKit, \(uiKitMeasurement.duration)")
    /// CoreImage
    let coreImageMeasurement = measure(originalImage.resize(to: newSize, with: .CoreImage))
    log("ResizeTechnique: CoreImage, \(coreImageMeasurement.duration)")
    /// CoreGraphics
    let coreGraphicsMeasurement = measure(originalImage.resize(to: newSize, with: .CoreGraphics))
    log("ResizeTechnique: CoreGraphics, \(coreGraphicsMeasurement.duration)")
    /// ImageIO
    let imageIOMeasurement = measure(originalImage.resize(to: newSize, with: .ImageIO))
    log("ResizeTechnique: ImageIO, \(imageIOMeasurement.duration)")
    /// Accelerate
    let accelerateMeasurement = measure(originalImage.resize(to: newSize, with: .Accelerate))
    log("ResizeTechnique: Accelerate, \(accelerateMeasurement.duration)")
    
}

func log(_ message: String) {
    print(message)
}

testImageResize()
