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
   
    lazy var detecor = OpenCVDetector(cameraView: cameraView, scale: 1, preset: .vga640x480, type: .back)
    
    lazy var models: [ModelCell] = {
        
        let ImageCollectionViewCellIdentifier = "ImageCollectionViewCellIdentifier"
        let ColorCollectionViewCellIdentifier = "ColorCollectionViewCellIdentifier"
        
        let images = [nil ,#imageLiteral(resourceName: "thshirtImage_5"), #imageLiteral(resourceName: "thshirtImage_1"), #imageLiteral(resourceName: "thshirtImage_3"), #imageLiteral(resourceName: "thshirtImage_2"), #imageLiteral(resourceName: "thshirtImage_4")]
        let colors = [nil ,#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1),#colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1),#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1),#colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1),#colorLiteral(red: 0.09019608051, green: 0, blue: 0.3019607961, alpha: 1),#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1),#colorLiteral(red: 0.3098039329, green: 0.01568627544, blue: 0.1294117719, alpha: 1),#colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1), #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)]
        
        let imageModel = ModelCell(cellClass: ImageCollectionViewCell.self, identifier: ImageCollectionViewCellIdentifier, items: images,
                                   configuration: { (cell, indexPath) in
                                    (cell as! ImageCollectionViewCell).image = images[indexPath.row]
        }) { (indexPath) in
            self.detecor.setImage(images[indexPath.row])
        }
        
        let colorModel = ModelCell(cellClass: ColorCollectionViewCell.self, identifier: ColorCollectionViewCellIdentifier, items: images,
                                   configuration: { (cell, indexPath) in
                                    (cell as! ColorCollectionViewCell).coloredLayer.backgroundColor = colors[indexPath.row]?.cgColor
        }) { (indexPath) in
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            
            if colors[indexPath.row]?.getRed(&red, green: &green, blue: &blue, alpha: nil) == true {
                self.detecor.setFillingColorWithRed(Double(red * 255), green: Double(green * 255), blue: Double(blue * 255))
            } else {
                self.detecor.resetFillingColor()
            }
        }
        
        return [colorModel, imageModel]
    }()
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var hValueLabel: UILabel!
    @IBOutlet weak var sValueLabel: UILabel!
    @IBOutlet weak var vValueLabel: UILabel!
    @IBOutlet weak var offsetValueLabel: UILabel!
    @IBOutlet weak var hValueSlider: UISlider!
    @IBOutlet weak var sValueSlider: UISlider!
    @IBOutlet weak var vValueSlider: UISlider!
    @IBOutlet weak var offsetValueSlider: UISlider!
    @IBOutlet weak var scalarView: UIView!
    
    private let CollectionTableViewCellIdentifier = "CollectionTableViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        
        detecor.startCapture()
        
        //UIGestureRecognizer
        let gesure = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.gestureAction(_:)))
        gesure.delegate = self
        cameraView.addGestureRecognizer(gesure)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CollectionTableViewCell", bundle: nil), forCellReuseIdentifier: CollectionTableViewCellIdentifier)
        tableView.isPagingEnabled = true
        tableView.contentInset = .zero
        
        hValueSlider.value = 4
        sValueSlider.value = 32
        vValueSlider.value = 32
        offsetValueLabel.text = "0"
        
        hsvDidChanged()
    }
    
    private func hsvDidChanged() {
        hValueLabel.text = "\(hValueSlider.value)"
        sValueLabel.text = "\(sValueSlider.value)"
        vValueLabel.text = "\(vValueSlider.value)"
        detecor.setHSVRangeValueWithHValue(hValueSlider.value,
                                           sValue: sValueSlider.value,
                                           vValue: vValueSlider.value)
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
        
        DispatchQueue.main.async {
            self.scalarView.backgroundColor = self.detecor.getAvarageDetectionColor()
        }
    }
    
    //MARK: Actions
   
    @IBAction func sliderValueAction(_ sender: UISlider) {
        hsvDidChanged()
    }
    
    @IBAction func sliderOffsetAction(_ sender: UISlider) {
        offsetValueLabel.text = "\(sender.value)"
        detecor.setOffset(sender.value)
    }
    
    @IBAction func detectFaceAction(_ sender: UIButton) {
        detecor.isShouldDetectFace = !sender.isSelected
        sender.isSelected.toggle()
    }
    
    @IBAction func cameraAction(_ sender: UIButton) {
        detecor.stopCapture()
        sender.isSelected.toggle()
        detecor.setCameraType(sender.isSelected ? .front : .back)
        detecor.startCapture()
    }
    
    @IBAction func detectionModeAction(_ sender: UIButton) {
        if detecor.detectionMode == .arrayScalars {
            detecor.detectionMode = .avarageScalar
            sender.setTitle("Avarage scalar mode", for: .normal)
        } else {
            detecor.detectionMode = .arrayScalars
            sender.setTitle("Array scalars mode", for: .normal)
        }
    }
}

extension CameraViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !tableView.frame.contains(touch.location(in: view))
    }
}

//MARK: - UITableViewDelegate

extension CameraViewController: UITableViewDelegate {
    
}


//MARK: - UITableViewDataSource

extension CameraViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height * 0.8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: CollectionTableViewCellIdentifier, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? CollectionTableViewCell {
            cell.bind(cell: models[indexPath.row])
            cell.collectionView.allowsMultipleSelection = false
            cell.collectionView.contentInset = .zero
            cell.collectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .left)
        }
    }
}

