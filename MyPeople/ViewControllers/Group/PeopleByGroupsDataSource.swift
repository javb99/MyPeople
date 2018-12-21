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
    
    public var stateController: StateController!
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
        //let personGroups = stateController.groups(forPerson: person.identifier!)
        
        //let rotatedGroups = groups[indexPath.section...] + groups[..<indexPath.section]
        let personsGroupsSorted = stateController.order(person.groupIDs)
        let colors = personsGroupsSorted.map{ stateController.group(for: $0).meta.color }
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
