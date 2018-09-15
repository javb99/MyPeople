//
//  CollapsibleDataSource.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/11/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

enum CollapsibleState {
    case collapsed
    case open
    case uncollapsible
}

class CollapsibleSectionsDataSource: NSObject, UICollectionViewDataSource {
    
    weak var collectionView: UICollectionView?
    
    var wrappedDataSource: UICollectionViewDataSource
    
    var states: [CollapsibleState]
    
    var defaultState: CollapsibleState
    
    init(collectionView: UICollectionView, wrapping dataSource: UICollectionViewDataSource, defaultState: CollapsibleState = .open) {
        self.collectionView = collectionView
        wrappedDataSource = dataSource
        self.defaultState = defaultState
        let count = wrappedDataSource.numberOfSections?(in: collectionView) ?? 0
        states = [CollapsibleState].init(repeating: defaultState, count: count)
    }
    
    func setUncollapsible(_ section: Int) {
        states[section] = .uncollapsible
        collectionView!.reloadSections([section])
    }
    
    func collapse(_ section: Int) {
        states[section] = .collapsed
        collectionView!.deleteItems(at: allIndexPaths(for: section))
    }
    
    func open(_ section: Int) {
        states[section] = .open
        collectionView!.insertItems(at: allIndexPaths(for: section))
    }
    
    func allIndexPaths(for section: Int) -> [IndexPath] {
        let itemCount = wrappedDataSource.collectionView(collectionView!, numberOfItemsInSection: section)
        guard itemCount > 0 else { return [] }
        return (0..<itemCount).map { IndexPath(item: $0, section: section) }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let newSectionCount = wrappedDataSource.numberOfSections?(in: collectionView) ?? 0
        let oldSectionCount = states.count
        // By this implementation everytime the section count changes ALL sections are reset to the default state.
        if oldSectionCount != newSectionCount {
            states = [CollapsibleState].init(repeating: defaultState, count: newSectionCount)
        }
        return newSectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch states[section] {
        case .collapsed:
            return 0
        case .open, .uncollapsible:
            return wrappedDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        }
    }
    
    // MARK: Pass on to wrapped DataSource
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return wrappedDataSource.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return wrappedDataSource.collectionView!(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return wrappedDataSource.collectionView?(collectionView, canMoveItemAt: indexPath) ?? false
    }
    
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        wrappedDataSource.collectionView?(collectionView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
    }
    
    public func indexTitles(for collectionView: UICollectionView) -> [String]? {
        return wrappedDataSource.indexTitles?(for: collectionView)
    }
    
    public func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
        return wrappedDataSource.collectionView!(collectionView, indexPathForIndexTitle: title, at: index)
    }
}
