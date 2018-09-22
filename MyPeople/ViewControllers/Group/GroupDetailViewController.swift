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
    public var group: Group!
    
    // MARK: Instance members
    private var cellsDataSource: PeopleByGroupsCellsDataSource!
    private var headerDataSource: SingleHeaderDataSource!
    
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        guard group != nil else {
            fatalError("Dependencies not fulfilled.")
        }
        
        navigationItem.title = group.name
        navigationItem.largeTitleDisplayMode = .never
        //navigationController?.navigationBar.barTintColor = group.color.settingAlpha(to: 0.2)
        navigationController?.navigationBar.tintColor = group.color
        
        headerDataSource = SingleHeaderDataSource(sourcingFrom: nil, headerDelegate: self, group: group)
        // TODO: Color circles don't work correctly without all the groups.
        cellsDataSource = PeopleByGroupsCellsDataSource(sourcingFrom: headerDataSource)
        cellsDataSource.groups = [group]
        collectionView.dataSource = cellsDataSource
        
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
        cellsDataSource.groups = [group]
        collectionView.reloadData()
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = group.people[indexPath.item]
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

extension GroupDetailViewController: GroupDetailHeaderViewDelegate {
    public func actionButtonPressed(action: GroupAction) {
        switch action {
        case .text:
            print("Send text to group.")
            let controller = MFMessageComposeViewController()
            controller.messageComposeDelegate = self
            let identifiers = group.people.compactMap { $0.identifier }
            controller.recipients = identifiers
            present(controller, animated: true, completion: nil)
        case .email:
            print("Send email to group")
            let controller = MFMailComposeViewController()
            controller.mailComposeDelegate = self
            let identifiers = group.people.compactMap { $0.name }
                .map { $0 + "@example.com" }
            controller.setToRecipients(identifiers)
            present(controller, animated: true, completion: nil)
        }
    }
    
    public func addMembersButtonPressed() {
        print("Add members")
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
