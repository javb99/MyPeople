//
//  PeopleByGroupsDataSource.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

/// Provides access to the array of groups using each group as a section full of all its members.
public class PeopleByGroupsDataSource: NSObject, UICollectionViewDataSource {
    
    public var groups: [Group] = []
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups[section].people.count
    }
    
    /// Rotate the colors for a person based on the section that is being asked for.
    func colors(forItemAt indexPath: IndexPath) -> [UIColor] {
        let person = self.person(at: indexPath)
        
        let rotatedGroups = groups[indexPath.section...] + groups[..<indexPath.section]
        let personsGroupsSorted = rotatedGroups.filter { person.groups.contains($0) }
        let colors = personsGroupsSorted.map{ $0.color }
        return colors
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let person = self.person(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyPeopleViewController.cellIdentifier, for: indexPath) as! PersonCell
        
        cell.viewModel = .init(person: person, colors: colors(forItemAt: indexPath))
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            // Deque GroupHeaderView
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPeopleViewController.headerIdentifier, for: indexPath) as! GroupHeaderView
            
            let group = self.group(atSection: indexPath.section)
            header.title = group.name
            header.color = group.color
            
            return header
            
        case SectionBackgroundView.kind:
            // Deque SectionBackgroundView
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: SectionBackgroundView.kind, withReuseIdentifier: SectionBackgroundView.kind, for: indexPath) as! SectionBackgroundView
            
            let group = self.group(atSection: indexPath.section)
            view.color = group.color
            return view
        default:
            fatalError()
        }
    }
    
    public func group(atSection section: Int) -> Group {
        return groups[section]
    }
    
    public func person(at indexPath: IndexPath) -> Person {
        return groups[indexPath.section].people[indexPath.item]
    }
}
