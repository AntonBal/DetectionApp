//
//  TableViewCell.swift
//  DetectionApp
//
//  Created by Anton Bal on 5/29/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

import UIKit

struct ModelCell {
    let cellClass: AnyClass
    let identifier: String
    let items: [Any?]
    let configuration: (_ cell: UICollectionViewCell, _ indexPath: IndexPath) -> Void
    let didSelect: (_ indexPath: IndexPath) -> Void
}

class CollectionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    private var cell: ModelCell!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func bind(cell: ModelCell) {
        self.cell = cell
        collectionView.register(cell.cellClass, forCellWithReuseIdentifier: cell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension CollectionTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let rect = bounds.insetBy(dx: 20, dy: 20)
        return CGSize(width: rect.height, height: rect.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 50
    }
}

extension CollectionTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let selectedItems = collectionView.indexPathsForSelectedItems?.filter({ $0.section == indexPath.section && $0.row != indexPath.row }) {
            selectedItems.forEach { collectionView.deselectItem(at: $0, animated: false) }
        }
        
        cell.didSelect(indexPath)
    }
}

extension CollectionTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cell.items.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectioCell = collectionView.dequeueReusableCell(withReuseIdentifier: cell.identifier, for: indexPath)
        cell.configuration(collectioCell, indexPath)
        return collectioCell
    }
}

