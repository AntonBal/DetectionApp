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
   
    lazy var detecor = OpenCVDetector(cameraView: cameraView, scale: 1, preset: .vga640x480, type: .front)
    
    let images = [nil ,#imageLiteral(resourceName: "thshirtImage_5"), #imageLiteral(resourceName: "thshirtImage_1"), #imageLiteral(resourceName: "thshirtImage_3"), #imageLiteral(resourceName: "thshirtImage_2"), #imageLiteral(resourceName: "thshirtImage_4")]
    let colors = [nil ,#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1),#colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1),#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1),#colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)]
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var coloredCollectionView: UICollectionView!
    
    private let ImageCollectionViewCellIdentifier = "ImageCollectionViewCellIdentifier"
    private let ColorCollectionViewCellIdentifier = "ColorCollectionViewCellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        
        detecor.startCapture()
        
        //UIGestureRecognizer
        let gesure = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.gestureAction(_:)))
        gesure.delegate = self
        view.addGestureRecognizer(gesure)
        
        //ColorCollectionView
        coloredCollectionView.allowsMultipleSelection = true
        coloredCollectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCellIdentifier)
        coloredCollectionView.register(ColorCollectionViewCell.self, forCellWithReuseIdentifier: ColorCollectionViewCellIdentifier)
        coloredCollectionView.delegate = self
        coloredCollectionView.dataSource = self
        coloredCollectionView.isPagingEnabled = true
        coloredCollectionView.contentInset = .zero
        coloredCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .left)
        coloredCollectionView.selectItem(at: IndexPath(row: 0, section: 1), animated: false, scrollPosition: .left)
    }
    
    @objc func gestureAction(_ gesture: UITapGestureRecognizer) {
        var location = gesture.location(in: view)
        
        let width: CGFloat = 480
        let height: CGFloat = 640
        
        let viewWidth = view.frame.width
        var viewHeight = view.frame.height
        viewHeight -= viewHeight - height //becaouse video not in full screen
        
        location.x = round((location.x * width) / viewWidth)
        location.y = round((location.y * height) / viewHeight)
        
        detecor.setDetecting(location)
    }
}

extension CameraViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !coloredCollectionView.frame.contains(touch.location(in: view))
    }
}

//MARK: - UICollectionViewDelegate

extension CameraViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      
        if let selectedItems = collectionView.indexPathsForSelectedItems?.filter({ $0.section == indexPath.section && $0.row != indexPath.row }) {
            selectedItems.forEach { collectionView.deselectItem(at: $0, animated: false) }
        }
        
        if indexPath.section == 0 {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            
            if colors[indexPath.row]?.getRed(&red, green: &green, blue: &blue, alpha: nil) == true {
                detecor.setFillingColorWithRed(Double(red * 255), green: Double(green * 255), blue: Double(blue * 255))
            } else {
                detecor.resetFillingColor()
            }
        } else {
            
        }
    }
}

extension CameraViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? colors.count : images.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var collectioCell: UICollectionViewCell?
        
        if indexPath.section == 0 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCollectionViewCellIdentifier, for: indexPath) as? ColorCollectionViewCell {
                cell.coloredLayer.backgroundColor = colors[indexPath.row]?.cgColor
                collectioCell = cell
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCellIdentifier, for: indexPath) as? ImageCollectionViewCell {
                cell.image = images[indexPath.row]
                collectioCell = cell
            }
        }
        
        return collectioCell ?? UICollectionViewCell()
    }
}
