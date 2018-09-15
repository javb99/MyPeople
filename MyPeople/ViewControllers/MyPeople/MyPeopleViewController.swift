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

public class GroupsDataSource: NSObject, UICollectionViewDataSource {
    
    public var headerTouchedCallback: ((UITapGestureRecognizer)->())?
    
    public var groups: [Group] = []
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups[section].people.count
    }
    
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
        
        cell.profileCircle.bgColors = colors(forItemAt: indexPath)
        cell.profileCircle.image = person.image
        cell.nameLabel.text = person.name
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            // Deque GroupHeaderView
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPeopleViewController.headerIdentifier, for: indexPath) as! GroupHeaderView
            
            let group = self.group(atSection: indexPath.section)
            
            view.backgroundColor = .white
            view.label.text = group.name
            view.color = group.color
            
            // Clear any left over gesture recognizers.
            view.gestureRecognizers = nil
            let headerTouchGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
            view.addGestureRecognizer(headerTouchGestureRecognizer)
            
            return view
            
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
    
    @IBAction func didTap(_ tapRecognizer: UITapGestureRecognizer) {
        headerTouchedCallback?(tapRecognizer)
    }
}

public class MyPeopleViewController: UICollectionViewController {
    
    static let cellIdentifier: String = "Cell"
    static let headerIdentifier: String = "Header"
    
    var collapsibleDataSource: CollapsibleSectionsDataSource!
    var naiveDataSource: GroupsDataSource!
    
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

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "My People"
        
        naiveDataSource = GroupsDataSource()
        naiveDataSource.headerTouchedCallback = { [weak self] gc -> ()  in
            self?.didTap(gc)
        }
        collapsibleDataSource = CollapsibleSectionsDataSource(collectionView: collectionView, wrapping: naiveDataSource, defaultState: .collapsed)
        collectionView.dataSource = collapsibleDataSource
        
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
                        self.naiveDataSource.groups = groups
                        self.collectionView.reloadData()
                    }
                    
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func didTap(_ tapRecognizer: UITapGestureRecognizer) {
        let location = tapRecognizer.location(in: collectionView)
        if let headerIndexPath = headerIndexPath(at: location) {
            toggleSection(headerIndexPath.section)
        }
    }
    
    func headerIndexPath(at location: CGPoint) -> IndexPath? {
        let visibleSupplementaryViews = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        let visibleHeaderFrames = visibleSupplementaryViews.map { $0.frame }
        let visibleIndexPaths = collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader)
        
        let frameContainsLocation: (CGRect, IndexPath) -> Bool = { (frame, _) -> Bool in
            return frame.contains(location)
        }
        
        // Zip frames to their indexPaths so we can return the first indexPath where its frame contains location.
        if let (_, indexPath) = zip(visibleHeaderFrames, visibleIndexPaths).first(where: frameContainsLocation) {
            return indexPath
        } else {
            return nil
        }
    }
    
    func toggleSection(_ section: Int) {
        switch collapsibleDataSource.states[section]  {
        case .collapsed:
            collapsibleDataSource.open(section)
        case .open:
            collapsibleDataSource.collapse(section)
        case .uncollapsible:
            break
        }
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = naiveDataSource.person(at: indexPath)
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
}
