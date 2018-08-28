//
//  ViewController.swift
//  ImageResizing
//
//  Created by Eugene Bokhan on 27/08/2018.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // UI Elements
    
    @IBOutlet weak var textView: UITextView!
    
    // Interface Actions
    
    @IBAction func runMeasurements(_ sender: Any) {
        textView.text = ""
        testImageResize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    // Measurements
    
    func testImageResize() {
        
        guard let originalImage = UIImage(named: "Clown Fish") else { return } // Use "Clown Fish JPEG" for jpeg version of the image
        
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
        textView.text += message + "\n\n"
    }
    
    
}

