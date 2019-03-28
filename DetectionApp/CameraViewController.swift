//
//  CameraViewController.swift
//  DetectionApp
//
//  Created by Anton Bal on 3/19/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
   
    lazy var detecor = OpenCVDetector(cameraView: view, scale: 0.5, preset: .vga640x480, type: .front)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detecor.startCapture()
        
        let gesure = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.gestureAction(_:)))
        view.addGestureRecognizer(gesure)
    }
    
    @objc func gestureAction(_ gesture: UITapGestureRecognizer) {
        var location = gesture.location(in: view)
        let viewWidth = view.frame.width
        let viewHeight = view.frame.height
        
        let width: CGFloat = 480
        let height: CGFloat = 640
        
        let w = viewWidth / width
        let h = viewHeight / height
        
        location.x /= w
        location.y /= h
        
        detecor.setDetecting(location)
    }
}
