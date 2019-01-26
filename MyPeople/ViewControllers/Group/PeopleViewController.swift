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

/// An object that is notified of changes to the selection of a table view, collection view, or other IndexPath based view.
public protocol SelectionListener: class {
    func indexPathSelected(_ indexPath: IndexPath)
    func indexPathDeselected(_ indexPath: IndexPath)
}

public protocol PeopleViewControllerEditDelegate: class {
    func didRemovePerson(_ person: Person)
    func didAddPerson(_ person: Person)
}

/// A class that displays People and allows the user to drill down into the detail page for each of them. When in editing mode, an add button is displayed. Use the contactPickerDelegate to be informed of new people that should be added.
public class PeopleViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: Dependencies
    public var navigationCoordinator: AppNavigationCoordinator
    //public var stateController: StateController
    
    /// Refreshed in getData()
//    public private(set) var group: Group? {
//        didSet {
//            groupID = group?.identifier
//            updateGroupColor()
//        }
//    }
    //public var groupID: Group.ID?
    
    /// The delegate that is assigned to be informed of new contacts to add.
    public var contactPickerDelegate: CNContactPickerDelegate?
    public var selectionListener: SelectionListener?
    
    // MARK: Instance members
    /// THe configuration of the nav bar before changes are made for this controller.
    private var incomingNavBarConfig: NavBarConfiguration?
    
    private var addCellDataSource: AddContactDataSource
    private var cellsDataSource: PeopleByGroupsDataSource
    
    /// The people that are displayed.
    public private(set) var people: [Person] = []
    
    /// Set the people property and update the collectionView if desired.
    public func setPeople(_ people: [Person], shouldReloadCollectionView: Bool = true) {
        self.people = people
        reloadData(shouldReloadCollectionView: shouldReloadCollectionView)
    }
    
    /// The color used for the background (dimmed) and for the tint color in the detail views.
    public var tintColor: UIColor? {
        didSet {
            updateTintColor()
        }
    }
    
    public private(set) var selectedIndexes: Set<IndexPath> = []
    
    private var templateCell: PersonCell = {
        let cell = PersonCell(frame: .zero)
        cell.viewModel = .init(name: "Khrystyna", profilePicture: nil, colors: [])
        return cell
    }()
    
    // MARK: Static members
    static let cellIdentifier: String = "Cell"
    
    // MARK: Initializers
    public init(navigationCoordinator: AppNavigationCoordinator, stateController: StateController) {
        self.navigationCoordinator = navigationCoordinator
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = templateCell.intrinsicContentSize
        flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        flowLayout.sectionInsetReference = .fromSafeArea
        
        cellsDataSource = PeopleByGroupsDataSource(sourcingFrom: nil)
        cellsDataSource.stateController = stateController
        addCellDataSource = AddContactDataSource(sourcingFrom: cellsDataSource)
        addCellDataSource.tintColor = tintColor ?? .black
        
        super.init(collectionViewLayout: flowLayout)
        
        clearsSelectionOnViewWillAppear = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        reloadData(shouldReloadCollectionView: false)
        collectionView.dataSource = addCellDataSource
        
        updateTintColor()
        
        collectionView.register(PersonCell.self, forCellWithReuseIdentifier: MyPeopleViewController.cellIdentifier)
        collectionView.register(AddContactDataSource.cellClass, forCellWithReuseIdentifier: AddContactDataSource.addCellIdentifier)
    }
    
    /// Passes the data to the data source and optionally refreshes the collectionView.
    func reloadData(shouldReloadCollectionView: Bool = true) {
        cellsDataSource.peopleByGroups = [people] // Only one group so wrap in an array.
        
        if shouldReloadCollectionView { // Don't lose selection because it is needed to delete.
            let indexes = selectedIndexes
            selectedIndexes = [] // Don't maintain selection because items could have moved.
            indexes.forEach { selectionListener?.indexPathDeselected($0) }
            collectionView.reloadData()
        }
    }
    
    /// Update the background color of the collection view to match the group color. Also updates the addCellsDataSource tintColor.
    func updateTintColor() {
        let color: UIColor = tintColor ?? .darkGray
        
        let bgColor = UIColor.white.overlay(color.withAlphaComponent(0.1))
        collectionView.setBackgroundColor(bgColor)
        addCellDataSource.tintColor = color
        
        if let addCell = addCellDataSource.addCellIndex { // Reload the add cell if it's displayed.
            collectionView.reloadItems(at: [addCell])
        }
    }
    
    /// Inform the receive that it should remove the selected indexes.
    public func removeSelectedItems() {
        // Capture the selection before it is cleared in reloadData()
        let removedIndexPaths = [IndexPath](selectedIndexes)
        //reloadData(shouldReloadCollectionView: false)
        collectionView.deleteItems(at: removedIndexPaths)
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
        guard let controller = try! navigationCoordinator.prepareContactDetailViewController(for: person.identifier) else { return }
        controller.view.tintColor = tintColor
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = tintColor
        show(controller, sender: self)
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditing {
            selectedIndexes.insert(indexPath)
            selectionListener?.indexPathSelected(indexPath)
        }
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedIndexes.remove(indexPath)
        selectionListener?.indexPathDeselected(indexPath)
    }
    
    /// All of the people that are selected in the collection view.
    public var selectedPeople: [Person.ID] {
        return selectedIndexes.map { people[addCellDataSource.transform($0).item].identifier }
    }
    
    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        // Check if this is a rotation.
        // Without this, the layout is only invalidated when rotating into landscape.
        if !coordinator.targetTransform.isIdentity {
            collectionViewLayout.invalidateLayout()
        }
    }
    
    public func addMembersButtonPressed() {
        print("Add members")
        let picker = CNContactPickerViewController()
        picker.delegate = contactPickerDelegate
        picker.predicateForSelectionOfProperty = nil
        picker.view.tintColor = tintColor
        present(picker, animated: true, completion: nil)
    }
}
