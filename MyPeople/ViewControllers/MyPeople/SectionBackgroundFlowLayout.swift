//
//  SectionBackgroundFlowLayout.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

class SectionBackgroundFlowLayout: UICollectionViewFlowLayout {
    var sectionBackgrounds: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        let sectionCount = collectionView.numberOfSections
        guard sectionCount > 0 else { return }
        
        // Calculate the section backgrounds.
        for section in 0..<sectionCount {
            let itemCount = collectionView.numberOfItems(inSection: section)
            // Don't show the background if there is no cells.
            guard itemCount > 0 else {  continue }
            let firstIndexPath = IndexPath(item: 0, section: section)
            let lastIndexPath = IndexPath(item: itemCount-1, section: section)
            guard let firstItemFrame = layoutAttributesForItem(at: firstIndexPath)?.frame, let lastItemFrame = layoutAttributesForItem(at: lastIndexPath)?.frame else { fatalError("Unexpected nil layout attributes provided by superclass implementation of prepare.") }
            
            // Fill the area under all the cells in the section and the sectionInsets
            let sectionRect = CGRect(x: 0,
                                     y: firstItemFrame.minY - sectionInset.top,
                                     width: collectionViewContentSize.width,
                                     height: sectionInset.top + lastItemFrame.maxY - firstItemFrame.minY + sectionInset.bottom)
            let indexPath = IndexPath(item: 0, section: section)
            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SectionBackgroundView.kind, with: indexPath)
            attributes.frame = sectionRect
            // Show behind cells.
            attributes.zIndex = -10
            sectionBackgrounds[indexPath] = attributes
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        var myAttributes: [UICollectionViewLayoutAttributes] = []
        for (_, bgAttributes) in sectionBackgrounds {
            if rect.intersects(bgAttributes.frame) {
                myAttributes.append(bgAttributes)
            }
        }
        
        return superAttributes + myAttributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case SectionBackgroundView.kind:
            return sectionBackgrounds[indexPath]
        default:
            return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }
    }
}
