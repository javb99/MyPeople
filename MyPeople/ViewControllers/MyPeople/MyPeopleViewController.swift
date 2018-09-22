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

public class MyPeopleViewController: UICollectionViewController {
    
    static let cellIdentifier: String = "Cell"
    static let headerIdentifier: String = "Header"
    
    var collapsibleDataSource: CollapsibleSectionsDataSource!
    var naiveDataSource: PeopleByGroupsDataSource!
    
    var addButton: UIButton!
    
    var contactStoreWrapper: ContactStoreWrapper
    
    public init() {
        let flowLayout = SectionBackgroundFlowLayout()
        flowLayout.sectionHeadersPinToVisibleBounds = true
        let templateHeader = GroupHeaderView(frame: .zero)
        templateHeader.title = "Hello World"
        flowLayout.headerReferenceSize = templateHeader.intrinsicContentSize
        let templateCell = PersonCell(frame: .zero)
        templateCell.viewModel = .init(name: "Khrystyna", profilePicture: nil, colors: [])
        flowLayout.itemSize = templateCell.intrinsicContentSize
        flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        
        contactStoreWrapper = ContactStoreWrapper()
        
        super.init(collectionViewLayout: flowLayout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "My People"
        
        naiveDataSource = PeopleByGroupsDataSource()
        collapsibleDataSource = CollapsibleSectionsDataSource(collectionView: collectionView, sourcingFrom: naiveDataSource, defaultState: .collapsed)
        collectionView.dataSource = collapsibleDataSource
        
        let bgView = UIView()
        bgView.frame = collectionView.bounds
        bgView.backgroundColor = .white
        collectionView.backgroundView = bgView
        
        collectionView.register(PersonCell.self, forCellWithReuseIdentifier: MyPeopleViewController.cellIdentifier)
        collectionView.register(GroupHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPeopleViewController.headerIdentifier)
        collectionView.register(SectionBackgroundView.self, forSupplementaryViewOfKind: SectionBackgroundView.kind, withReuseIdentifier: SectionBackgroundView.kind)
        
        let addGroupButton = UIButton(type: .custom)
        addButton = addGroupButton
        addGroupButton.addTarget(self, action: #selector(newGroupButtonPressed(_:)), for: .touchUpInside)
        addGroupButton.setTitle("Add", for: .normal)
        addGroupButton.standardStyle()
        
        collectionView.addSubview(addGroupButton)
        addGroupButton.positionAboveSectionHeaders()
        addGroupButton.use([
            addGroupButton.leadingAnchor.constraint(equalToSystemSpacingAfter: collectionView.safeAreaLayoutGuide.leadingAnchor, multiplier: 1.0),
            collectionView.safeAreaLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: addGroupButton.bottomAnchor, multiplier: 1.0)])
        
        contactStoreWrapper.requestAccess { (result) in
            if result == .success {
                do {
                    // Store unique identifier to person pairs.
                    var allContacts: [String: Person] = [:]
                    
                    var colorIndex = 0
                    
                    let contactGroups = try self.contactStoreWrapper.backingStore.groups(matching: nil)
                    let groups = contactGroups.map { contactGroup -> Group in
                        colorIndex += 1
                        return Group(contactGroup, color: UIColor.color(for: colorIndex))
                    }
                    
                    for group in groups {
                        let contactsInGroup = try self.contactStoreWrapper.backingStore.unifiedContacts(matching: group.containedContactsPredicate!, keysToFetch: Person.requiredContactKeys)
                        
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
            //toggleSection(headerIndexPath.section)
            let groupDetailController = GroupDetailViewController()
            groupDetailController.group = naiveDataSource.groups[headerIndexPath.section]
            navigationController?.pushViewController(groupDetailController, animated: true)
        }
    }
    
    @IBAction func newGroupButtonPressed(_ button: UIButton?) {
        let alertView = UIAlertController(title: "New Group", message: "Enter a group name", preferredStyle: .alert)
        alertView.addTextField(configurationHandler: nil)
        let done = UIAlertAction(title: "Add", style: .default) { [weak self] (action)  in
            let textField = alertView.textFields!.first!
            guard let text = textField.text, !text.isEmpty else { fatalError() }
            try! self?.contactStoreWrapper.addGroup(named: text)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertView.addAction(done)
        alertView.addAction(cancel)
        present(alertView, animated: true, completion: nil)
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
        let state = collapsibleDataSource.states[section]
        switch state  {
        case .collapsed:
            collapsibleDataSource.open(section)
        case .open:
            collapsibleDataSource.collapse(section)
        case .uncollapsible:
            break
        }
    }
    
    public override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        
        if elementKind == UICollectionView.elementKindSectionHeader {
            let header = (view as! CollectionViewCollapsibleSectionHeader)
            header.gestureRecognizers = nil
            let headerTouchGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
            header.addGestureRecognizer(headerTouchGestureRecognizer)
        }
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = naiveDataSource.groups[indexPath.section].people[indexPath.item]
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
