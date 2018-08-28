//
//  Detailed Resize Measurements.swift
//  ImageResizing
//
//  Created by Eugene Bokhan on 28/08/2018.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import UIKit
import CoreGraphics
import Accelerate

extension UIImage {
    
    // MARK - UIKit
    
    public func performDetailedMeasurementUIKit(to newSize: CGSize) -> (UIImage, String) {
        var resultImage = self
        var measurementResult = ""
        
        measurementResult += "UIGraphicsBeginImageContextWithOptions: "
            + measure(UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)).duration + "\n\n"
        
        measurementResult += "self.draw(in: CGRect): "
            + measure(self.draw(in: CGRect(origin: .zero, size: newSize))).duration + "\n\n"
        
        let UIGraphicsGetImageFromCurrentImageContextMeasurement = measure(UIGraphicsGetImageFromCurrentImageContext())
        
        measurementResult += "UIGraphicsGetImageFromCurrentImageContext: "
            + measure(measurementResult).duration + "\n\n"
        
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContextMeasurement.result else { return (resultImage, measurementResult) }
        
        resultImage = resizedImage
        
        measurementResult += "UIGraphicsEndImageContext: "
            + measure(UIGraphicsEndImageContext()).duration
        
        return (resultImage, measurementResult)
    }
    
    // MARK: - CoreImage
    
    public func performDetailedMeasurementCoreImage(to newSize: CGSize) -> (UIImage, String) {
        var resultImage = self
        var measurementResult = ""
        
        guard let cgImage = cgImage else { return (resultImage, measurementResult) }
        
        let ciImageMeasurement = measure(CIImage(cgImage: cgImage))
        measurementResult += "CIImage(cgImage: cgImage): "
        + ciImageMeasurement.duration + "\n\n"
        let ciImage = ciImageMeasurement.result
        
        let scale = (Double)(newSize.width) / (Double)(ciImage.extent.size.width)
        
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value:scale), forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey:kCIInputAspectRatioKey)
        
        let ciFilterMeasurement = measure(filter.value(forKey: kCIOutputImageKey) as! CIImage)
        measurementResult += "CIOutputImage: "
        + ciFilterMeasurement.duration + "\n\n"
        let outputImage = ciFilterMeasurement.result
        
        let ciContextMeasurement = measure(CIContext(options: [.useSoftwareRenderer: false]))
        measurementResult += "CIContext(options: ): "
        + ciContextMeasurement.duration + "\n\n"
        let context = ciContextMeasurement.result
        
        let resultImageMeasuremenet = measure(UIImage(cgImage: context.createCGImage(outputImage, from: outputImage.extent)!))
        measurementResult += "UIImage(cgImage: ): "
        + resultImageMeasuremenet.duration + "\n\n"
        resultImage = resultImageMeasuremenet.result
        return (resultImage, measurementResult)
    }
    
    // MARK: - CoreGraphics
    
    public func performDetailedMeasurementCoreGraphics(to newSize: CGSize) -> (UIImage, String) {
        var resultImage = self
        var measurementResult = ""
        
        guard let cgImage = cgImage else { return (resultImage, measurementResult) }
        
        let width = Int(newSize.width)
        let height = Int(newSize.height)
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace!
        let bitmapInfo = cgImage.bitmapInfo
        
        let cgContextMeasurement = measure(CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue))
        measurementResult += "CGContext(data: ... )"
        + cgContextMeasurement.duration + "\n\n"
        guard let context = cgContextMeasurement.result else { return (resultImage, measurementResult) }
        
        context.interpolationQuality = .high
        let rect = CGRect(origin: CGPoint.zero, size: newSize)
        
        let contextDrawMeasurement = measure(context.draw(cgImage, in: rect))
        measurementResult += "context.draw: "
            + contextDrawMeasurement.duration + "\n\n"
        
        let resultImageMeasurement = measure(context.makeImage().flatMap { UIImage(cgImage: $0) }!)
        measurementResult += "context.makeImage: "
            + resultImageMeasurement.duration + "\n\n"
        
        resultImage = resultImageMeasurement.result
        
        return (resultImage, measurementResult)
    }
    
    // MARK: - ImageIO
    
    public func performDetailedMeasurementImageIO(to newSize: CGSize) -> (UIImage, String) {
        var resultImage = self
        var measurementResult = ""
        
        let pngDataMeasurement = measure(pngData())
        measurementResult += "pngData init: "
            + pngDataMeasurement.duration + "\n\n"
        guard let pngData = pngDataMeasurement.result else { return (resultImage, measurementResult) }
        
        let imageCFDataMeasurement = measure(NSData(data: pngData) as CFData)
        measurementResult += "NSData(data: pngData): "
            + imageCFDataMeasurement.duration + "\n\n"
        let imageCFData = imageCFDataMeasurement.result
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max(newSize.width, newSize.height)
            ] as CFDictionary
        
        let sourceMeasurement = measure(CGImageSourceCreateWithData(imageCFData, nil)!)
        measurementResult += "CGImageSourceCreateWithData: "
            + sourceMeasurement.duration + "\n\n"
        let source = sourceMeasurement.result
        
        let createThumbnailMeasurement = measure(CGImageSourceCreateThumbnailAtIndex(source, 0, options))
        measurementResult += "CGImageSourceCreateThumbnailAtIndex: "
            + createThumbnailMeasurement.duration + "\n\n"
        guard let imageReference = createThumbnailMeasurement.result else { return (resultImage, measurementResult) }
        resultImage = UIImage(cgImage: imageReference)
        
        return (resultImage, measurementResult)
    }
    
    // MARK: - Accelerate
    
    public func performDetailedMeasurementAccelerate(to newSize: CGSize) -> (UIImage, String) {
        var resultImage = self
        var measurementResult = ""
        
        guard let cgImage = cgImage else { return (resultImage, measurementResult) }
        
        // create a source buffer
        let vImage_CGImageFormatMeasurement = measure(vImage_CGImageFormat(bitsPerComponent: numericCast(cgImage.bitsPerComponent),
                                                                           bitsPerPixel: numericCast(cgImage.bitsPerPixel),
                                                                           colorSpace: Unmanaged.passUnretained(cgImage.colorSpace!),
                                                                           bitmapInfo: cgImage.bitmapInfo,
                                                                           version: 0,
                                                                           decode: nil,
                                                                           renderingIntent: .defaultIntent))
        measurementResult += "vImage_CGImageFormat: "
            + vImage_CGImageFormatMeasurement.duration + "\n\n"
        var format = vImage_CGImageFormatMeasurement.result
        
        let vImage_BufferMeasurement = measure(vImage_Buffer())
        measurementResult += "vImage_Buffer: "
            + vImage_BufferMeasurement.duration + "\n\n"
        var sourceBuffer = vImage_BufferMeasurement.result
        
        defer {
            sourceBuffer.data.deallocate()
        }
        
        let vImageBuffer_InitWithCGImageMeasurement = measure(vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags)))
        measurementResult += "vImageBuffer_InitWithCGImage: "
            + vImageBuffer_InitWithCGImageMeasurement.duration + "\n\n"
        var error = vImageBuffer_InitWithCGImageMeasurement.result
        
        guard error == kvImageNoError else { return (resultImage, measurementResult) }
        
        // create a destination buffer
        let destWidth = Int(newSize.width)
        let destHeight = Int(newSize.height)
        let bytesPerPixel = cgImage.bitsPerPixel
        let destBytesPerRow = destWidth * bytesPerPixel
        
        let dataAllocateMeasurement = measure(UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow))
        measurementResult += "dataAllocate: "
            + dataAllocateMeasurement.duration + "\n\n"
        let destData = dataAllocateMeasurement.result
        
        defer {
            destData.deallocate()
        }
        
        let vImage_BufferFillMeasurement = measure(vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow))
        measurementResult += "vImage_BufferFill: "
            + vImage_BufferFillMeasurement.duration + "\n\n"
        var destBuffer = vImage_BufferFillMeasurement.result
        
        // scale the image
        let vImageScale_ARGB8888Measuremet = measure(vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling)))
        measurementResult += "vImageScale_ARGB8888: "
            + vImageScale_ARGB8888Measuremet.duration + "\n\n"
        error = vImageScale_ARGB8888Measuremet.result
        
        guard error == kvImageNoError else { return (resultImage, measurementResult) }
        
        // create a CGImage from vImage_Buffer
        let vImageCreateCGImageFromBufferMeasurement = measure(vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue())
        measurementResult += "vImageCreateCGImageFromBuffer: "
            + vImageCreateCGImageFromBufferMeasurement.duration + "\n\n"
        let destCGImage = vImageCreateCGImageFromBufferMeasurement.result
        guard error == kvImageNoError else { return (resultImage, measurementResult) }
        
        // create a UIImage
        let resultImageMeasurement = measure(destCGImage.flatMap({ UIImage(cgImage: $0) }))
        measurementResult += "resultImage: "
            + resultImageMeasurement.duration + "\n\n"
        if let scaledImage = resultImageMeasurement.result {
            resultImage = scaledImage
        }
        
        return (resultImage, measurementResult)
    }
    
}
