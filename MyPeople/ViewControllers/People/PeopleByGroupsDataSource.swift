//
//  PeopleByGroupsDataSource.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

/// Provides the people in a group.
public class PeopleByGroupsDataSource: ChainableDataSource {
    
    /// A stateController is needed to get the color rings for the groups a person is a member of.
    public var stateController: StateController!
    /// An array of people arrays. Each array corrosponds to a group.
    public var peopleByGroups: [[Person]] = []
    
    public override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return peopleByGroups.count
    }
    
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return peopleByGroups[section].count
    }
    
    /// Rotate the colors for a person based on the section that is being asked for.
    func colors(forItemAt indexPath: IndexPath) -> [UIColor] {
        let person = self.person(at: indexPath)
        let personsGroups = stateController.groups(forPerson: person.identifier).map { $0.identifier }
        let personsGroupsSorted = stateController.order(personsGroups)
        let colors = personsGroupsSorted.map{ stateController.group(for: $0).meta.color }
        return colors
    }
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let person = self.person(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupsViewController.cellIdentifier, for: indexPath) as! PersonCell
        
        cell.viewModel = .init(person: person, colors: colors(forItemAt: indexPath))
        
        return cell
    }
    
    public func person(at indexPath: IndexPath) -> Person {
        return peopleByGroups[indexPath.section][indexPath.item]
    }
}
