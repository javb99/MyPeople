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
import MessageUI

public class SingleHeaderDataSource: ChainableDataSource {
    
    var headerDelegate: ActionButtonsHeaderDelegate
    var group: Group
    
    public init(sourcingFrom dataSource: UICollectionViewDataSource? = nil, headerDelegate: ActionButtonsHeaderDelegate, group: Group) {
        self.headerDelegate = headerDelegate
        self.group = group
        super.init(sourcingFrom: dataSource)
    }
    
    public override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GroupDetailViewController.headerIdentifier, for: indexPath) as! ActionButtonsHeader
            header.delegate = headerDelegate
            header.color = group.meta.color
            return header
        default:
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
    }
}

public class GroupDetailViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: Dependencies
    public var navigationCoordinator: AppNavigationCoordinator!
    public var stateController: StateController!
    public var groupID: Group.ID!
    
    // MARK: Instance members
    /// THe configuration of the nav bar before changes are made for this controller.
    private var incomingNavBarConfig: NavBarConfiguration?
    private var addCellDataSource: AddContactDataSource!
    private var cellsDataSource: PeopleByGroupsCellsDataSource!
    private var headerDataSource: SingleHeaderDataSource!
    private var people: [Person]!
    private var group: Group!
    
    private var templateHeader: ActionButtonsHeader = {
        let headerCell = ActionButtonsHeader()
        return headerCell
    }()
    private var templateCell: PersonCell = {
        let cell = PersonCell(frame: .zero)
        cell.viewModel = .init(name: "Khrystyna", profilePicture: nil, colors: [])
        return cell
    }()
    
    // MARK: Static members
    static let cellIdentifier: String = "Cell"
    static let headerIdentifier: String = "GroupDetailViewController.Header"
    
    // MARK: Initializers
    public init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.headerReferenceSize = CGSize(width: 300, height: 150)
        flowLayout.itemSize = templateCell.intrinsicContentSize
        flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        flowLayout.sectionInsetReference = .fromSafeArea
        
        super.init(collectionViewLayout: flowLayout)
        
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
        
        guard navigationCoordinator != nil, groupID != nil else {
            fatalError("Dependencies not fulfilled.")
        }
        
        getData()
        
        headerDataSource = SingleHeaderDataSource(sourcingFrom: nil, headerDelegate: self, group: group)
        cellsDataSource = PeopleByGroupsCellsDataSource(sourcingFrom: headerDataSource)
        cellsDataSource.stateController = stateController
        addCellDataSource = AddContactDataSource(sourcingFrom: cellsDataSource)
        addCellDataSource.tintColor = group.meta.color
        
        loadDataSource()
        collectionView.dataSource = addCellDataSource
        
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.title = group.name
        navigationItem.largeTitleDisplayMode = .always
        
        guard let navController = navigationController else {
            fatalError("GroupDetailViewController not inside a UINavigationController")
        }
        incomingNavBarConfig = navController.navigationBar.currentConfig
        let config = navBarConfig()
        navController.navigationBar.apply(config)
        
        let bgView = UIView()
        bgView.frame = collectionView.bounds
        bgView.backgroundColor = UIColor.white.overlay(group.meta.color.withAlphaComponent(0.1))
        collectionView.backgroundView = bgView
        bgView.usesAutoLayout()
        bgView.constrain(to: collectionView)
        
        collectionView.register(PersonCell.self, forCellWithReuseIdentifier: MyPeopleViewController.cellIdentifier)
        collectionView.register(AddContactDataSource.cellClass, forCellWithReuseIdentifier: AddContactDataSource.addCellIdentifier)
        collectionView.register(ActionButtonsHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupDetailViewController.headerIdentifier)
    }
    
    func navBarConfig() -> NavBarConfiguration {
        var navBarConfig = NavBarConfiguration()
        navBarConfig.shadowImage = UIImage()
        navBarConfig.barTintColor = group.meta.color.withAlphaComponent(0.2)
        navBarConfig.tintColor = .white
        navBarConfig.barStyle = .blackTranslucent
        navBarConfig.isTranslucent = false
        return navBarConfig
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadDataSource()
        collectionView.reloadData()
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
    func loadDataSource() {
        getData()
        templateHeader.color = .black
        cellsDataSource.groups = [group]
        cellsDataSource.people = [people]
    }
    
    public override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        addCellDataSource.shouldShowAddButton = editing
        if editing {
            collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
        } else {
            collectionView.deleteItems(at: [IndexPath(item: 0, section: 0)])
        }
    }
    
    /// Present detail view controller for the person at the selected IndexPath.
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Show the add members dialog.
        if addCellDataSource.isAddCellIndex(indexPath) {
            addMembersButtonPressed()
            return
        }
        
        // Otherwise show the contact detail screen.
        let transformedIP = addCellDataSource.transform(indexPath)
        let person = people[transformedIP.item]
        
        let controller = try! navigationCoordinator.prepareContactDetailViewController(forContactIdentifiedBy: person.identifier.rawValue)
        controller.allowsEditing = false
        controller.view.tintColor = group.meta.color
        navigationController?.pushViewController(controller, animated: true)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return templateHeader.sizeThatFits(collectionView.bounds.size)
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
        loadDataSource()
        collectionView.reloadData()
    }
    
    public func addMembersButtonPressed() {
        print("Add members")
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.predicateForSelectionOfProperty = nil
        present(picker, animated: true, completion: nil)
    }
}

extension GroupDetailViewController: ActionButtonsHeaderDelegate {
    public func actionButtonPressed(action: GroupAction) {
        switch action {
        case .text:
            print("Send text to group.")
            let controller = MFMessageComposeViewController()
            controller.messageComposeDelegate = self
            let identifiers = people.compactMap { $0.phoneNumber }
            controller.recipients = identifiers.map { $0.rawValue }
            present(controller, animated: true, completion: nil)
        case .email:
            print("Send email to group")
            let controller = MFMailComposeViewController()
            controller.mailComposeDelegate = self
            let identifiers = people.compactMap { $0.email }
            controller.setToRecipients(identifiers.map { $0.rawValue })
            present(controller, animated: true, completion: nil)
        }
    }
}

extension GroupDetailViewController: CNContactPickerDelegate {
    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        addContactsToGroup(contacts)
        dismiss(animated: true, completion: nil)
    }
    
    func addContactsToGroup(_ contacts: [CNContact]) {
        for contact in contacts {
            stateController.add(person: Person.ID(rawValue: contact.identifier), toGroup: group.identifier)
        }
        loadDataSource()
        collectionView.reloadData()
    }
}

extension GroupDetailViewController: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension GroupDetailViewController: MFMessageComposeViewControllerDelegate {
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
