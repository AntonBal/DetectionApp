//
//  ViewController.swift
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let imageview = UIImageView()
    var openCVWrapper: OpenCVDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageview.frame = view.bounds
        imageview.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        openCVWrapper = OpenCVDetector(cameraView: imageview, scale: 0.8)
        openCVWrapper.startCapture()
        
        view.addSubview(imageview)
    }
}

