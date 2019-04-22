//
//  ColorCollectionViewCell.swift
//  DetectionApp
//
//  Created by Anton Bal on 4/8/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

import UIKit

class ColorCollectionViewCell: UICollectionViewCell {
    
    lazy var coloredLayer: CALayer = {
        let coloredLayer = CALayer()
        coloredLayer.frame = bounds
        coloredLayer.borderWidth = 3.5
        coloredLayer.cornerRadius = bounds.width / 2
        layer.addSublayer(coloredLayer)
        return coloredLayer
    }()
    
    override var isSelected: Bool {
        didSet {
            coloredLayer.borderColor = isSelected ? UIColor.red.cgColor : UIColor.black.cgColor
        }
    }
}
