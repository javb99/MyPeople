//
//  SectionBackgroundFlowLayout.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

let debugLayoutMethods = false

class SectionBackgroundFlowLayout: UICollectionViewFlowLayout {
    var sectionBackgrounds: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    
    override func prepare() {
        if debugLayoutMethods { print("super.prepare()") }
        super.prepare()
        if debugLayoutMethods { print("self.prepare()") }
        sectionBackgrounds.removeAll(keepingCapacity: true)
        guard let collectionView = collectionView else { return }
        let sectionCount = collectionView.numberOfSections
        guard sectionCount > 0 else { return }
        
        // Calculate the section backgrounds.
        for section in 0..<sectionCount {
            let itemCount = collectionView.numberOfItems(inSection: section)
            // Don't show the background if there is no cells.
            if debugLayoutMethods { print("--\"Inside prepare()\" itemCount in section(\(section)): \(itemCount)") }
            guard let attributes = createSectionBackgroundAttributes(for: section) else { continue }
            sectionBackgrounds[attributes.indexPath] = attributes
        }
    }
    
    func createSectionBackgroundAttributes(for section: Int) -> UICollectionViewLayoutAttributes? {
        let itemCount = collectionView!.numberOfItems(inSection: section)
        if debugLayoutMethods { print("--\"Inside prepare()\" itemCount in section(\(section)): \(itemCount)") }
        // Don't show the background if there is no cells.
        guard itemCount > 0 else {  return nil }
        let firstIndexPath = IndexPath(item: 0, section: section)
        let lastIndexPath = IndexPath(item: itemCount-1, section: section)
        guard let firstItemFrame = layoutAttributesForItem(at: firstIndexPath)?.frame, let lastItemFrame = layoutAttributesForItem(at: lastIndexPath)?.frame else { fatalError("Unexpected nil layout attributes provided by superclass implementation of prepare.") }
        
        return createSectionBackgroundAttributes(for: section, firstItemFrame: firstItemFrame, lastItemFrame: lastItemFrame)
    }
    
    func createSectionBackgroundAttributes(for section: Int, firstItemFrame: CGRect, lastItemFrame: CGRect) -> UICollectionViewLayoutAttributes? {
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
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if debugLayoutMethods { print("layoutAttributesForElements(in: \(rect))") }
        guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        if debugLayoutMethods { print(" super -> \(superAttributes.map { $0.representedElementKind ?? "Cell/Other" })") }
        var myAttributes: [UICollectionViewLayoutAttributes] = []
        for (_, bgAttributes) in sectionBackgrounds {
            if rect.intersects(bgAttributes.frame) {
                myAttributes.append(bgAttributes)
            }
        }
        if debugLayoutMethods { print(" self -> \(myAttributes.map { $0.representedElementKind ?? "Cell/Other" })") }
        return superAttributes + myAttributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if debugLayoutMethods { print("layoutAttributesForSupplementaryView(ofKind: \(elementKind), at: \(indexPath) -> ...") }
        switch elementKind {
        case SectionBackgroundView.kind:
            return sectionBackgrounds[indexPath]
        default:
            return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }
    }
    
    override func invalidateLayout() {
        if debugLayoutMethods { print("invalidateLayout()") }
        super.invalidateLayout()
    }
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if debugLayoutMethods { print("invalidateLayout(with: \(context.debugDescription))") }
        super.invalidateLayout(with: context)
    }
    
    var sectionsToRemove: [IndexPath] = []
    var sectionsToAdd: [IndexPath] = []
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        if debugLayoutMethods { print("super.prepare(forCollectionViewUpdates(...)") }
        super.prepare(forCollectionViewUpdates: updateItems)
        if debugLayoutMethods { print("self.prepare(forCollectionViewUpdates(...)") }
        var sectionsToAddedCount = [Int: Int]()
        for update in updateItems {
            switch update.updateAction {
            case .insert:
                if debugLayoutMethods { print("--Prepare for insertion at (\(update.indexPathAfterUpdate!.section),\(update.indexPathAfterUpdate!.item))") }
                let section = update.indexPathAfterUpdate!.section
                sectionsToAddedCount[section] = 1 + (sectionsToAddedCount[section] ?? 0)
            case .delete:
                if debugLayoutMethods { print("--Prepare for deletion at (\(update.indexPathBeforeUpdate!.section),\(update.indexPathBeforeUpdate!.item))") }
                let section = update.indexPathBeforeUpdate!.section
                if collectionView!.numberOfItems(inSection: section) == 0 {
                    if debugLayoutMethods { print("----Prepare to remove section \(section)") }
                    sectionsToRemove.append(IndexPath(item: 0, section: section))
                }
            case .move, .reload, .none:
                break
            }
        }
        
        for (section, addedCount) in sectionsToAddedCount {
            if collectionView!.numberOfItems(inSection: section) == addedCount {
                if debugLayoutMethods { print("----Prepare to add section \(section)") }
                sectionsToAdd.append(IndexPath(item: 0, section: section))
            }
        }
    }
    
    override func indexPathsToDeleteForSupplementaryView(ofKind elementKind: String) -> [IndexPath] {
        let indexPaths = super.indexPathsToDeleteForSupplementaryView(ofKind: elementKind)
        if debugLayoutMethods { print("super.indexPathsToDeleteForSupplementaryView(ofKind: \(elementKind)) -> \(indexPaths)") }
        switch elementKind {
        case SectionBackgroundView.kind:
            if debugLayoutMethods { print("self -> \(sectionsToRemove)") }
            return sectionsToRemove
        default:
            return indexPaths
        }
    }
    
    override func indexPathsToInsertForSupplementaryView(ofKind elementKind: String) -> [IndexPath] {
        let indexPaths = super.indexPathsToInsertForSupplementaryView(ofKind: elementKind)
        if debugLayoutMethods { print("super.indexPathsToInsertForSupplementaryView(ofKind: \(elementKind)) -> \(indexPaths)") }
        switch elementKind {
        case SectionBackgroundView.kind:
            if debugLayoutMethods { print("self -> \(sectionsToAdd)") }
            return sectionsToAdd
        default:
            return indexPaths
        }
    }
    
    override func finalizeCollectionViewUpdates() {
        if debugLayoutMethods { print("finalizeCollectionViewUpdates()") }
        super.finalizeCollectionViewUpdates()
        sectionsToRemove = []
        sectionsToAdd = []
    }
    
    /// The section background starts 2 points tall and the width of the header and hidden using an alpha of 0. at the center of the header.
    func animationAttributesForSectionBackground(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let itemCount = collectionView!.numberOfItems(inSection: indexPath.section)
        guard itemCount > 0 else {  return nil }
        
        guard let attributes = createSectionBackgroundAttributes(for: indexPath.section) else { fatalError() }
        
        let headerAttributes = super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath)!

        let xScale = headerAttributes.frame.width / attributes.frame.size.width
        let yScale = 2 / attributes.frame.size.height
        
        attributes.center = headerAttributes.center
        // Scale to width of header and height of 2.
        attributes.transform = attributes.transform.scaledBy(x: xScale, y: yScale)
        attributes.alpha = 0
        
        return attributes
    }
    
    override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case SectionBackgroundView.kind:
            if sectionsToAdd.contains(elementIndexPath) {
                // Animate the element at this index path from these attributes to the normal attributes.
                // Slides down from the section header to its new position as it fades in.
                return animationAttributesForSectionBackground(at: elementIndexPath)
                
            } else {
                // This signals to use the standard attributes for this indexPath.
                return nil
            }
        default:
            return super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath)
        }
    }

//    override func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        switch elementKind {
//        case SectionBackgroundView.kind:
//            if sectionsToRemove.contains(elementIndexPath) {
//                // Animate the element at this index path from these attributes to the normal attributes.
//                // Slides down from the section header to its new position as it fades in.
//                //return animationAttributesForSectionBackground(at: elementIndexPath)
//                return nil
//            } else {
//                return nil
//            }
//        default:
//            return super.finalLayoutAttributesForDisappearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath)
//        }
//    }
}
