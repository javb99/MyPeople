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
    
    var headerDelegate: GroupDetailHeaderViewDelegate
    var group: Group
    
    public init(sourcingFrom dataSource: UICollectionViewDataSource? = nil, headerDelegate: GroupDetailHeaderViewDelegate, group: Group) {
        self.headerDelegate = headerDelegate
        self.group = group
        super.init(sourcingFrom: dataSource)
    }
    
    public override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GroupDetailViewController.headerIdentifier, for: indexPath) as! GroupDetailHeaderView
            header.delegate = headerDelegate
            header.model = .init(group: group)
            return header
        default:
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
    }
}

public class GroupDetailViewController: UICollectionViewController {
    
    // MARK: Dependencies
    public var navigationCoordinator: AppNavigationCoordinator!
    public var stateController: StateController!
    public var groupID: String!
    
    // MARK: Instance members
    private var cellsDataSource: PeopleByGroupsCellsDataSource!
    private var headerDataSource: SingleHeaderDataSource!
    private var people: [Person]!
    private var group: Group!
    
    // MARK: Static members
    static let cellIdentifier: String = "Cell"
    static let headerIdentifier: String = "GroupDetailViewController.Header"
    
    // MARK: Initializers
    public init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.headerReferenceSize = CGSize(width: 300, height: 150)
        let templateCell = PersonCell(frame: .zero)
        templateCell.viewModel = .init(name: "Khrystyna", profilePicture: nil, colors: [])
        flowLayout.itemSize = templateCell.intrinsicContentSize
        flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        
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
        // TODO: Color circles don't work correctly without all the groups.
        cellsDataSource = PeopleByGroupsCellsDataSource(sourcingFrom: headerDataSource)
        loadDataSource()
        collectionView.dataSource = cellsDataSource
        
        navigationItem.title = group.name
        navigationItem.largeTitleDisplayMode = .never
        //navigationController?.navigationBar.barTintColor = group.color.settingAlpha(to: 0.2)
        navigationController?.navigationBar.tintColor = group.color
        
        let bgView = UIView()
        bgView.frame = collectionView.bounds
        bgView.backgroundColor = .white
        let coloredView = UIView()
        coloredView.frame = bgView.bounds
        coloredView.backgroundColor = group.color.settingAlpha(to: 0.1)
        bgView.addSubview(coloredView)
        collectionView.backgroundView = bgView
        
        collectionView.register(PersonCell.self, forCellWithReuseIdentifier: MyPeopleViewController.cellIdentifier)
        collectionView.register(GroupDetailHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupDetailViewController.headerIdentifier)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadDataSource()
        collectionView.reloadData()
    }
    
    /// Loads group and members.
    func getData() {
        guard let group = stateController.groups[groupID] else {
            fatalError("Invalid groupID dependency")
        }
        self.group = group
        people = stateController.members(ofGroup: groupID)
    }
    
    /// Loads data and passes it to the data source.
    func loadDataSource() {
        getData()
        cellsDataSource.groups = [group]
        cellsDataSource.people = [people]
    }
    
    /// Present detail view controller for the person at the selected IndexPath.
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = people[indexPath.item]
        guard person.isBackedByContact else { return }
        
        let controller = try! navigationCoordinator.prepareContactDetailViewController(forContactIdentifiedBy: person.identifier!)
        controller.allowsEditing = false
        navigationController?.pushViewController(controller, animated: true)
    }
    
    /// Called when the stateController's state is changed. We use this to reload the collection view.
    @objc func appStateDidChange() {
        loadDataSource()
        collectionView.reloadData()
    }
}

extension GroupDetailViewController: GroupDetailHeaderViewDelegate {
    public func actionButtonPressed(action: GroupAction) {
        switch action {
        case .text:
            print("Send text to group.")
            let controller = MFMessageComposeViewController()
            controller.messageComposeDelegate = self
            let identifiers = people.compactMap { $0.phoneNumber }
            controller.recipients = identifiers
            present(controller, animated: true, completion: nil)
        case .email:
            print("Send email to group")
            let controller = MFMailComposeViewController()
            controller.mailComposeDelegate = self
            let identifiers = people.compactMap { $0.email }
            controller.setToRecipients(identifiers)
            present(controller, animated: true, completion: nil)
        }
    }
    
    public func addMembersButtonPressed() {
        print("Add members")
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.predicateForSelectionOfProperty = nil
        present(picker, animated: true, completion: nil)
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
            stateController.add(person: contact.identifier, toGroup: group.identifier!)
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