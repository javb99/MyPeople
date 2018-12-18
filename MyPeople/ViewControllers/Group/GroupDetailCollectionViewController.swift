//
//  GroupDetailViewController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions
import Contacts
import ContactsUI

public class GroupDetailCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: Dependencies
    public var navigationCoordinator: AppNavigationCoordinator!
    public var stateController: StateController!
    public var modalListener: GroupDetailModalListener!
    public var groupID: Group.ID!
    
    // MARK: Instance members
    /// THe configuration of the nav bar before changes are made for this controller.
    private var incomingNavBarConfig: NavBarConfiguration?
    
    private var addCellDataSource: AddContactDataSource!
    private var cellsDataSource: PeopleByGroupsDataSource!
    
    /// Set in getData()
    public private(set) var people: [Person]!
    /// Set in getData()
    public private(set) var group: Group!
    
    public private(set) var selectedIndexes: Set<IndexPath> = []
    
    private var templateCell: PersonCell = {
        let cell = PersonCell(frame: .zero)
        cell.viewModel = .init(name: "Khrystyna", profilePicture: nil, colors: [])
        return cell
    }()
    
    // MARK: Static members
    static let cellIdentifier: String = "Cell"
    
    // MARK: Initializers
    public init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = templateCell.intrinsicContentSize
        flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        flowLayout.sectionInsetReference = .fromSafeArea
        
        super.init(collectionViewLayout: flowLayout)
        
        clearsSelectionOnViewWillAppear = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(appStateDidChange), name: .stateDidChange, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        guard navigationCoordinator != nil, groupID != nil, modalListener != nil else {
            fatalError("Dependencies not fulfilled.")
        }
        
        getData()
        
        cellsDataSource = PeopleByGroupsDataSource(sourcingFrom: nil)
        cellsDataSource.stateController = stateController
        addCellDataSource = AddContactDataSource(sourcingFrom: cellsDataSource)
        addCellDataSource.tintColor = group.meta.color
        
        reloadData()
        collectionView.dataSource = addCellDataSource
        
        let bgView = UIView()
        bgView.frame = collectionView.bounds
        bgView.backgroundColor = UIColor.white.overlay(group.meta.color.withAlphaComponent(0.1))
        collectionView.backgroundView = bgView
        bgView.usesAutoLayout()
        bgView.constrain(to: collectionView)
        
        collectionView.register(PersonCell.self, forCellWithReuseIdentifier: MyPeopleViewController.cellIdentifier)
        collectionView.register(AddContactDataSource.cellClass, forCellWithReuseIdentifier: AddContactDataSource.addCellIdentifier)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData()
    }
    
    /// Loads group and members.
    func getData() {
        guard let group = stateController.groupsTable[groupID] else {
            fatalError("Invalid groupID dependency")
        }
        self.group = group
        people = stateController.members(ofGroup: groupID)
    }
    
    /// Loads data and passes it to the data source.
    func reloadData() {
        getData()
        cellsDataSource.groups = [group]
        cellsDataSource.people = [people]
        selectedIndexes = [] // Don't maintain selection because items could have moved.
        collectionView.reloadData()
    }
    
    public override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if !editing {
            selectedIndexes = []
            // Sync with selectedIndexes.
            collectionView.indexPathsForSelectedItems?.forEach { (indexPath) in
                collectionView.deselectItem(at: indexPath, animated: true)
            }
        }
        
        toggleAddButton(to: editing)
        collectionView.allowsMultipleSelection = editing
    }
    
    /// passing a value of true shows the add button and a value of false hides it. Only mangages the data source and insertion and deletion from the collection view.
    func toggleAddButton(to shouldShow: Bool) {
        addCellDataSource.shouldShowAddButton = shouldShow
        let addButtonIndex = IndexPath(item: 0, section: 0)
        if shouldShow {
            collectionView.insertItems(at: [addButtonIndex])
        } else {
            collectionView.deleteItems(at: [addButtonIndex])
        }
    }
    
    /// Used to intercept the touch on a cell before the selection highlight is applied.
    /// Special behaviour for the add person cell and touching a cell to show the detail view.
    public override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        if isEditing {
            if addCellDataSource.isAddCellIndex(indexPath) {
                addMembersButtonPressed()
                return false // Avoid showing the selection highlight
            }
            return true
        }
        
        // Otherwise show the contact detail screen.
        let transformedIP = addCellDataSource.transform(indexPath)
        let person = people[transformedIP.item]
        showContactDetailScreen(for: person)
        
        return false // Avoid showing the selection highlight
    }
    
    public func showContactDetailScreen(for person: Person) {
        let controller = try! navigationCoordinator.prepareContactDetailViewController(forContactIdentifiedBy: person.identifier.rawValue)
        controller.allowsEditing = false
        controller.view.tintColor = group.meta.color
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = group.meta.color
        show(controller, sender: self)
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditing {
            selectedIndexes.insert(indexPath)
        }
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedIndexes.remove(indexPath)
    }
    
    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        // Check if this is a rotation.
        // Without this, the layout is only invalidated when rotating into landscape.
        if !coordinator.targetTransform.isIdentity {
            collectionViewLayout.invalidateLayout()
        }
    }
    
    /// Called when the stateController's state is changed. We use this to reload the collection view.
    @objc func appStateDidChange() {
        reloadData()
    }
    
    public func addMembersButtonPressed() {
        print("Add members")
        let picker = CNContactPickerViewController()
        picker.delegate = modalListener
        picker.predicateForSelectionOfProperty = nil
        picker.view.tintColor = group.meta.color
        present(picker, animated: true, completion: nil)
    }
}
