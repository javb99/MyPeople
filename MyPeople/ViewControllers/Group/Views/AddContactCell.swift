//
//  AddContactCell.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 11/18/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

extension PersonCell {
    
    func configureAsAddButton(tintColor: UIColor) {
        viewModel.colors = [.white]
        viewModel.name = "Add"
        viewModel.profilePicture = AssetCatalog.image(.addButton)
        self.tintColor = tintColor
    }
}

/// Provides an add contact button in the first slot. Provides methods to transform an index path.
public class AddContactDataSource: ChainableDataSource {
    
    static let cellClass = PersonCell.self
    static let addCellIdentifier = "AddContactCell"
    
    
    public var shouldShowAddButton: Bool = false
    
    /// The tint color applied to the add button cell.
    public var tintColor: UIColor = .green
    
    
    public func isAddCellIndex(_ indexPath: IndexPath) -> Bool {
        return shouldShowAddButton && indexPath.section == 0 && indexPath.item == 0
    }
    
    public override init(sourcingFrom dataSource: UICollectionViewDataSource?) {
        super.init(sourcingFrom: dataSource)
        self.indexTransform = IndexPathTransform(
            apply: { [unowned self] indexPath  in
                if indexPath.section == 0 && self.shouldShowAddButton {
                    return IndexPath(item: indexPath.item - 1, section: indexPath.section)
                } else {
                    return indexPath
                }
            },
            undo: { [unowned self] indexPath in
                if indexPath.section == 0 && self.shouldShowAddButton {
                    return IndexPath(item: indexPath.item + 1, section: indexPath.section)
                } else {
                    return indexPath
                }
            }
        )
    }
    
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let superCount = super.collectionView(collectionView, numberOfItemsInSection: section)
        if section == 0 && shouldShowAddButton {
            return superCount + 1
        }
        return superCount
    }
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isAddCellIndex(indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddContactDataSource.addCellIdentifier, for: indexPath) as! PersonCell
            cell.configureAsAddButton(tintColor: tintColor)
            return cell

        } else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }
    }
}
