//
//  CollapsibleDataSource.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/11/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

public protocol CollapsibleSectionHeader: class {
    var state: CollapsibleState { get set }
}

public enum CollapsibleState {
    case collapsed
    case open
    case uncollapsible
}

public typealias CollectionViewCollapsibleSectionHeader = UICollectionReusableView & CollapsibleSectionHeader

/// Holds state about which sections are collapsed. And changes the item count in each section to show that. All headers used must conform to CollapsibleSectionHeader.
public class CollapsibleSectionsDataSource: ChainableDataSource {
    
    weak var collectionView: UICollectionView!
    
    var states: [CollapsibleState]
    
    var defaultState: CollapsibleState
    
    init(collectionView: UICollectionView, sourcingFrom dataSource: UICollectionViewDataSource, defaultState: CollapsibleState = .open) {
        self.collectionView = collectionView
        self.defaultState = defaultState
        states = []
        super.init(sourcingFrom: dataSource)
        let count = previousDataSource?.numberOfSections?(in: collectionView) ?? defaults.numberOfSections
        states = [CollapsibleState].init(repeating: defaultState, count: count)
    }
    
    public func header(forSection section: Int) -> CollectionViewCollapsibleSectionHeader {
        return collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section)) as! CollectionViewCollapsibleSectionHeader
    }
    
    private func set(state: CollapsibleState, forHeaderAt section: Int) {
        // Change the disclosure indicator
        states[section] = state
        header(forSection: section).state = state
    }
    
    public func setUncollapsible(_ section: Int) {
        set(state: .uncollapsible, forHeaderAt: section)
        collectionView.reloadSections([section])
    }
    
    public func collapse(_ section: Int) {
        set(state: .collapsed, forHeaderAt: section)
        collectionView.deleteItems(at: allIndexPaths(for: section))
    }
    
    public func open(_ section: Int) {
        set(state: .open, forHeaderAt: section)
        collectionView.insertItems(at: allIndexPaths(for: section))
    }
    
    func allIndexPaths(for section: Int) -> [IndexPath] {
        let itemCount = previousDataSource!.collectionView(collectionView, numberOfItemsInSection: section)
        guard itemCount > 0 else { return [] }
        return (0..<itemCount).map { IndexPath(item: $0, section: section) }
    }
    
    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        let newSectionCount = previousDataSource!.numberOfSections!(in: collectionView)
        let oldSectionCount = states.count
        // By this implementation every time the section count changes ALL sections are reset to the default state.
        if oldSectionCount != newSectionCount {
            states = [CollapsibleState].init(repeating: defaultState, count: newSectionCount)
        }
        return newSectionCount
    }
    
    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch states[section] {
        case .collapsed:
            return 0
        case .open, .uncollapsible:
            return previousDataSource!.collectionView(collectionView, numberOfItemsInSection: section)
        }
    }
    
    public override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = previousDataSource!.collectionView!(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        if kind == UICollectionView.elementKindSectionHeader {
            (view as! CollectionViewCollapsibleSectionHeader).state = states[indexPath.section]
        }
        return view
    }
}
