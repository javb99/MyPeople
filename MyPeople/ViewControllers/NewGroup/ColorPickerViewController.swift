//
//  ColorPickerViewController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 1/22/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import UIKit

protocol ColorPickerDelegate: class {
    /// The color has been selected. Currently single selection is all that is allowed.
    /// Use this callback to dismiss the controller if needed.
    func colorPicker(_ picker: ColorPickerViewController, didSelect color: AssetCatalog.Color)
}

fileprivate let colorCellID = "ColorCell"

/// A ViewController that allows the user to select a color from a predefined selection of colors.
/// The delegate is informed every time the a color is chosen.
class ColorPickerViewController: UICollectionViewController {
    
    weak var delegate: ColorPickerDelegate?
    
    let colors: [AssetCatalog.Color] = AssetCatalog.Color.groupColors
    
    public var backgroundColor: UIColor = .clear {
        didSet {
            collectionView.setBackgroundColor(backgroundColor)
            collectionView.backgroundColor = backgroundColor
        }
    }
    
    init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = .init(singleValue: 8)
        flowLayout.sectionInsetReference = .fromSafeArea
        super.init(collectionViewLayout: flowLayout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundColor = .clear
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: colorCellID)
    }
    
    override var preferredContentSize: CGSize {
        get { return CGSize(width: CGFloat.greatestFiniteMagnitude, height: collectionViewLayout.collectionViewContentSize.height) }
        set {}
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: colorCellID, for: indexPath)
        let color = AssetCatalog.color(colors[indexPath.item])
        cell.contentView.backgroundColor = color
        cell.contentView.maskToCorners(ofRadius: 8)
        updateSelection(in: cell, at: indexPath)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            fatalError("Selected index path doesn't yield a cell. We must have made a false assumption about the cellForItem(at:) method.")
        }
        updateSelection(in: cell, at: indexPath)
        let color = colors[indexPath.item]
        delegate?.colorPicker(self, didSelect: color)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            fatalError("Selected index path doesn't yield a cell. We must have made a false assumption about the cellForItem(at:) method.")
        }
        updateSelection(in: cell, at: indexPath)
    }
    
    /// Updates the cell to its selected or unselected state based on its inclusion in the collectionView's selectedItems.
    func updateSelection(in cell: UICollectionViewCell, at indexPath: IndexPath) {
        if collectionView.isItemSelected(at: indexPath) {
            // Cell should display as selected.
            cell.contentView.border(of: .white, width: 2)
        } else {
            // Cell should display as normal - not selected.
            cell.contentView.border(of: .white, width: 3)
        }
    }
}
