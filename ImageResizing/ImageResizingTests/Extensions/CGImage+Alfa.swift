import CoreGraphics

public extension CGImage {

    func withCangedAlfaInfo(to alfaInfo: CGImageAlphaInfo) throws -> CGImage {
        guard let colorSpace = self.colorSpace,
              let context = CGContext(data: nil,
                                      width: self.width,
                                      height: self.height,
                                      bitsPerComponent: self.bitsPerComponent,
                                      bytesPerRow: self.bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: alfaInfo.rawValue)
        else { throw Error.cgContextCreationFailed }
        context.interpolationQuality = .high

        context.draw(self,
                     in: .init(origin: .zero,
                               size: .init(width: self.width,
                                           height: self.height)))

        guard let resultCGImage = context.makeImage()
        else { throw Error.cgContextCreationFailed }

        return resultCGImage
    }
    
}
