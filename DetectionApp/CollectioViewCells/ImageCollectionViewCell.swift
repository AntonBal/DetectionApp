//
//  ImageCollectionViewCell.swift
//  DetectionApp
//
//  Created by Anton Bal on 4/8/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    var image: UIImage? {
        didSet {
            let cgImage = image?.cgImage
            layer.contents = cgImage
            layer.contentsGravity = CALayerContentsGravity.resizeAspect
        }
    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = 2.5
            layer.borderColor = isSelected ? UIColor.red.cgColor : UIColor.black.cgColor
        }
    }
}
