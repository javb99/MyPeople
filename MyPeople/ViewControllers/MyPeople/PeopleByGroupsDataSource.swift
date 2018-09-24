//
//  PeopleByGroupsDataSource.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

/// Provides access to the array of groups using each group as a section full of all its members.
public class PeopleByGroupsDataSource: ChainableDataSource {
    
    public var groups: [Group] = [] {
        didSet {
            cellProvider.groups = groups
            supplementaryProvider.groups = groups
        }
    }
    
    public var people: [[Person]] = [] {
        didSet {
            cellProvider.people = people
        }
    }
    
    var cellProvider: PeopleByGroupsCellsDataSource
    var supplementaryProvider: PeopleByGroupsSupplementaryViewDataSource
    
    public override init(sourcingFrom dataSource: UICollectionViewDataSource? = nil) {
        cellProvider = .init(sourcingFrom: dataSource)
        supplementaryProvider = .init(sourcingFrom: cellProvider)
        super.init(sourcingFrom: supplementaryProvider)
    }
}

/// Provides the cells divided into sections by their group.
public class PeopleByGroupsCellsDataSource: ChainableDataSource {
    
    public var groups: [Group] = []
    public var people: [[Person]] = []
    
    public override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people[section].count
    }
    
    /// Rotate the colors for a person based on the section that is being asked for.
    func colors(forItemAt indexPath: IndexPath) -> [UIColor] {
        let person = self.person(at: indexPath)
        
        let rotatedGroups = groups[indexPath.section...] + groups[..<indexPath.section]
        let personsGroupsSorted = rotatedGroups.filter { person.groupIDs.contains($0.identifier!
            ) }
        let colors = personsGroupsSorted.map{ $0.color }
        return colors
    }
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let person = self.person(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyPeopleViewController.cellIdentifier, for: indexPath) as! PersonCell
        
        cell.viewModel = .init(person: person, colors: colors(forItemAt: indexPath))
        
        return cell
    }
    
    public func group(atSection section: Int) -> Group {
        return groups[section]
    }
    
    public func person(at indexPath: IndexPath) -> Person {
        return people[indexPath.section][indexPath.item]
    }
}

/// Provides the group name headers and the colored section backgrounds and NO cells. Intended to be chained with a data source that provides cells.
class PeopleByGroupsSupplementaryViewDataSource: ChainableDataSource {
    
    public var groups: [Group] = []
    
    public override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            // Deque GroupHeaderView
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPeopleViewController.headerIdentifier, for: indexPath) as! GroupHeaderView
            
            let group = groups[indexPath.section]
            header.title = group.name
            header.color = group.color
            
            return header
            
        case SectionBackgroundView.kind:
            // Deque SectionBackgroundView
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: SectionBackgroundView.kind, withReuseIdentifier: SectionBackgroundView.kind, for: indexPath) as! SectionBackgroundView
            
            let group = groups[indexPath.section]
            view.color = group.color
            return view
        default:
            fatalError()
        }
    }
}
