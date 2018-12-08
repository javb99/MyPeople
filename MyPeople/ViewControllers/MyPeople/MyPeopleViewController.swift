//
//  MyPeopleViewController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions
import Contacts
import ContactsUI

public class MyPeopleViewController: UICollectionViewController {
    
    // MARK: Static Members
    
    static let cellIdentifier: String = "Cell"
    static let headerIdentifier: String = "Header"
    
    // MARK: Instance Members
    
    var collapsibleDataSource: CollapsibleSectionsDataSource!
    var naiveDataSource: PeopleByGroupsDataSource!
    
    // MARK: Dependencies
    
    var navigationCoordinator: AppNavigationCoordinator!
    var stateController: StateController!
    
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
        flowLayout.sectionInsetReference = .fromSafeArea
        
        super.init(collectionViewLayout: flowLayout)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appStateDidChange), name: .stateDidChange, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        guard navigationCoordinator != nil, stateController != nil else {
            fatalError("Dependencies not provided.")
        }
        
        navigationItem.title = "My People"
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newGroupButtonPressed(_:)))
        navigationItem.setRightBarButton(addButton, animated: false)
        
        naiveDataSource = PeopleByGroupsDataSource()
        naiveDataSource.cellProvider.stateController = stateController
        collapsibleDataSource = CollapsibleSectionsDataSource(collectionView: collectionView, sourcingFrom: naiveDataSource, defaultState: .collapsed)
        collectionView.dataSource = collapsibleDataSource
        
        loadDataSource()
        collectionView.reloadData()
        
        let bgView = UIView()
        bgView.frame = collectionView.bounds
        bgView.backgroundColor = .white
        collectionView.backgroundView = bgView
        
        collectionView.register(PersonCell.self, forCellWithReuseIdentifier: MyPeopleViewController.cellIdentifier)
        collectionView.register(GroupHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPeopleViewController.headerIdentifier)
        collectionView.register(SectionBackgroundView.self, forSupplementaryViewOfKind: SectionBackgroundView.kind, withReuseIdentifier: SectionBackgroundView.kind)
    }
    
    func navBarConfig() -> NavBarConfiguration {
        var config = NavBarConfiguration()
        config.tintColor = .black
        config.barTintColor = .white
        config.barStyle = .default
        config.titleTextAttributes = .some(nil)
        config.largeTitleTextAttributes = .some(nil)
        return config
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.navigationBar.apply(navBarConfig())
        
        loadDataSource()
        collectionView.reloadData()
    }
    
    func loadDataSource() {
        let groups = stateController.orderedGroupIDs.map { stateController.group(forID: $0) }
        naiveDataSource.groups = groups
        var people = [[Person]]()
        for group in groups {
            people.append(stateController.members(ofGroup: group.identifier))
        }
        naiveDataSource.people = people
    }
    
    @objc func appStateDidChange() {
        loadDataSource()
        collectionView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func sectionTitleTapped(_ tapRecognizer: UITapGestureRecognizer) {
        let location = tapRecognizer.location(in: collectionView)
        if let headerIndexPath = collectionView.headerIndexPath(at: location) {
            let group = naiveDataSource.groups[headerIndexPath.section]
            let groupDetailController = navigationCoordinator.prepareGroupDetailViewController(for: group.identifier)
            navigationController?.pushViewController(groupDetailController, animated: true)
        }
    }
    
    @IBAction func newGroupButtonPressed(_ button: UIButton?) {
        let alertView = UIAlertController(title: "New Group", message: "Enter a group name", preferredStyle: .alert)
        alertView.addTextField(configurationHandler: nil)
        let done = UIAlertAction(title: "Add", style: .default) { [weak self] (action)  in
            let textField = alertView.textFields!.first!
            guard let text = textField.text, !text.isEmpty else { fatalError() }
            self?.stateController.createNewGroup(text, meta: GroupMeta(color: AssetCatalog.Color.groupColors.randomElement()!))
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertView.addAction(done)
        alertView.addAction(cancel)
        present(alertView, animated: true, completion: nil)
    }
    
    public override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        
        if elementKind == UICollectionView.elementKindSectionHeader {
            let header = (view as! GroupHeaderView)
            header.titleTouchedCallback = sectionTitleTapped(_:)
        }
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = naiveDataSource.people[indexPath.section][indexPath.item]
        
        let controller = try! navigationCoordinator.prepareContactDetailViewController(forContactIdentifiedBy: person.identifier.rawValue)
        navigationController?.pushViewController(controller, animated: true)
    }
}
