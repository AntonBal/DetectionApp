//
//  ViewController.swift
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var openCVWrapper: OpenCVDetector!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        openCVWrapper = OpenCVDetector(cameraView: imageView, scale: 1, type: .back)
        openCVWrapper.startCapture()
        
//        let detector = BodyDetector()
//        imageView.image = detector.detectAndDraw(imageView.image!)
    }
}

