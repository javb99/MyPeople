//
//  MyPeopleViewController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

func person(name: String, in groups: [Group]) -> Person {
    let person = Person(name: name)
    for group in groups {
        group.add(person)
    }
    return person
}

public class MyPeopleViewController: UICollectionViewController {
    
    static let cellIdentifier: String = "Cell"
    static let headerIdentifier: String = "Header"
    
    public init() {
        let flowLayout = SectionBackgroundFlowLayout()
        flowLayout.sectionHeadersPinToVisibleBounds = true
        let templateHeader = GroupHeaderView(frame: .zero)
        templateHeader.label.text = "Hello World"
        flowLayout.headerReferenceSize = templateHeader.intrinsicContentSize
        flowLayout.estimatedItemSize = CGSize(width: 80, height: 90)
        flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        super.init(collectionViewLayout: flowLayout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static let colors: [UIColor] = [.red, .blue, .purple, .green, .cyan, .orange, .black]
    
    var groups: [Group] = []

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "My People"
        
        let bgView = UIView()
        bgView.frame = collectionView.bounds
        bgView.backgroundColor = .white
        collectionView.backgroundView = bgView
        
        collectionView.register(PersonCell.self, forCellWithReuseIdentifier: MyPeopleViewController.cellIdentifier)
        collectionView.register(GroupHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPeopleViewController.headerIdentifier)
        collectionView.register(SectionBackgroundView.self, forSupplementaryViewOfKind: SectionBackgroundView.kind, withReuseIdentifier: SectionBackgroundView.kind)
        
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if granted {
                do {
                    // Store unique identifier to person pairs.
                    var allContacts: [String: Person] = [:]
                    
                    var colorIndex = 0
                    let colors = MyPeopleViewController.colors
                    func nextColor() -> UIColor {
                        let color = colors[colorIndex % colors.count]
                        colorIndex += 1
                        return color
                    }
                    
                    let contactGroups = try store.groups(matching: nil)
                    let groups = contactGroups.map { Group($0, color: nextColor()) }
                    
                    for group in groups {
                        let contactsInGroup = try store.unifiedContacts(matching: group.containedContactsPredicate!, keysToFetch: Person.requiredContactKeys)
                        
                        let peopleInGroup = contactsInGroup.map(Person.init)
                        
                        // Add each person to this group.
                        for person in peopleInGroup {
                            // Only create one instance of a Person.
                            // May need to account for unification using isUnified...
                            if let matchingPerson = allContacts[person.identifier!] {
                                group.add(matchingPerson)
                            } else {
                                allContacts[person.identifier!] = person
                                group.add(person)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.groups = groups
                        self.collectionView.reloadData()
                    }
                    
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups[section].people.count
    }
    
    func colors(forItemAt indexPath: IndexPath) -> [UIColor] {
        let person = groups[indexPath.section].people[indexPath.item]
        
        let rotatedGroups = groups[indexPath.section...] + groups[..<indexPath.section]
        let personsGroupsSorted = rotatedGroups.filter { person.groups.contains($0) }
        let colors = personsGroupsSorted.map{ $0.color }
        return colors
    }
    
    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let person = groups[indexPath.section].people[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyPeopleViewController.cellIdentifier, for: indexPath) as! PersonCell
        
        cell.profileCircle.bgColors = colors(forItemAt: indexPath)
        cell.profileCircle.image = person.image
        cell.nameLabel.text = person.name
        
        return cell
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = groups[indexPath.section].people[indexPath.item]
        guard person.isBackedByContact else { return }
        
        let store = CNContactStore()
        guard let contact = try? store.unifiedContact(withIdentifier: person.identifier!, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()]) else {
            print("Couldn't fetch full contact")
            return
        }
        let controller = CNContactViewController(for: contact)
        controller.allowsEditing = false
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPeopleViewController.headerIdentifier, for: indexPath) as! GroupHeaderView
            let group = groups[indexPath.section]
            print(indexPath)
            view.backgroundColor = .white
            view.label.text = group.name
            view.color = group.color
            return view
        case SectionBackgroundView.kind:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: SectionBackgroundView.kind, withReuseIdentifier: SectionBackgroundView.kind, for: indexPath) as! SectionBackgroundView
            let group = groups[indexPath.section]
            view.color = group.color
            return view
        default:
            fatalError()
        }
    }
}
