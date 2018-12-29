//
//  GroupDetailViewController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 11/23/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions
import MessageUI


/// Manages the action bar above the collection view along with the naviagation bar.
public class GroupDetailViewController: UIViewController, SelectionListener {
    
    // MARK: Dependencies
    public var navigationCoordinator: AppNavigationCoordinator
    public var stateController: StateController
    public var groupID: Group.ID
    // Filled during init based on the groupID.
    private var group: Group
    
    // MARK: Instance members
    public var collectionViewController: GroupDetailCollectionViewController
    private var gradientView: GradientView
    private var toolbar: GroupDetailToolbar
    
    private var modalListener: GroupDetailModalListener
    
    /// Vends the available actions to the toolbar.
    private var toolbarDataSource: GroupDetailToolbarDataSource
    
    
    /// Fails if the groupID doesn't resolve to a Group with the stateController.
    public init?(navigationCoordinator: AppNavigationCoordinator, stateController: StateController, groupID: Group.ID) {
        self.navigationCoordinator = navigationCoordinator
        self.stateController = stateController
        self.groupID = groupID
        group = stateController.group(for: groupID)
        modalListener = GroupDetailModalListener(group: group, stateController: stateController)
        
        collectionViewController = GroupDetailCollectionViewController(navigationCoordinator: navigationCoordinator, stateController: stateController, group: group)
        gradientView = GradientView(frame: .zero)
        toolbar = GroupDetailToolbar()
        toolbarDataSource = GroupDetailToolbarDataSource()
        toolbar.dataSource = toolbarDataSource
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.title = group.name
        navigationItem.largeTitleDisplayMode = .always
        
        configureCollectionViewController()
        addGradient()
        addActionButtons()
        
        addConstraints()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController!.navigationBar.apply(navBarConfig())
    }
    
    /// Configure the gradient view's attributes and add it as a subview.
    func addGradient() {
        gradientView.startColor = UIColor.white.overlay(group.meta.color.withAlphaComponent(0.5))
        gradientView.startPoint = .unitCenterTop
        gradientView.endColor = group.meta.color
        gradientView.endPoint = .unitCenterBottom
        view.addSubview(gradientView)
    }
    
    /// Configure the action buttons view's attributes and add it as a subview.
    func addActionButtons() {
        let weakActionButtonPressed: (Action)->() = { [weak self] action in
            self?.actionButtonPressed(action: action)
        }
        toolbar.buttonPressedCallback = weakActionButtonPressed
        toolbar.buttonTint = group.meta.color
        toolbar.reloadButtons()
        view.addSubview(toolbar)
    }
    
    /// Fill dependencies of the collectionViewController
    func configureCollectionViewController() {
        collectionViewController.navigationCoordinator = navigationCoordinator
        collectionViewController.stateController = stateController
        collectionViewController.groupID = groupID
        collectionViewController.modalListener = modalListener
        collectionViewController.selectionListener = self
        
        addChild(collectionViewController)
        view.addSubview(collectionViewController.view)
    }
    
    /// Set and activate the layout constraints. Views should already be added as subviews.
    func addConstraints() {
        guard collectionViewController.view.superview === view, gradientView.superview === view, toolbar.superview === view else {
            fatalError("Subviews were not added before constraints.")
        }
        
        let collectionView = collectionViewController.view!
        collectionView.usesAutoLayout()
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        gradientView.usesAutoLayout()
        let navBarHeight = navigationController!.navigationBar.frame.height
        gradientView.topAnchor.constraint(equalTo: view.topAnchor, constant: -navBarHeight).isActive = true
        gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        gradientView.bottomAnchor.constraint(equalTo: collectionViewController.view.topAnchor).isActive = true
        
        toolbar.usesAutoLayout()
        toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        toolbar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        let spaceBelowActionButtons: CGFloat = 6
        toolbar.bottomAnchor.constraint(equalTo: collectionViewController.view.topAnchor, constant: -spaceBelowActionButtons).isActive = true
    }
    
    func navBarConfig() -> NavBarConfiguration {
        var navBarConfig = NavBarConfiguration()
        navBarConfig.shadowImage = UIImage()
        navBarConfig.barTintColor = .clear
        navBarConfig.tintColor = .white
        navBarConfig.barStyle = .blackTranslucent
        navBarConfig.isTranslucent = true
        navBarConfig.backgroundImage = UIImage()
        return navBarConfig
    }
    
    public override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Allow the collection view to show the add and remove buttons.
        collectionViewController.setEditing(editing, animated: animated)
        
        // Change the tool bar.
        toolbarDataSource.isEditing = editing
        toolbar.reloadButtons()
    }
    
    public func indexPathSelected(_ indexPath: IndexPath) {
        // Enable any buttons that rely on having a selection.
        toolbarDataSource.hasSelection = !collectionViewController.selectedIndexes.isEmpty
        toolbar.reloadButtons()
    }
    
    public func indexPathDeselected(_ indexPath: IndexPath) {
        // Disable any buttons that rely on having a selection.
        toolbarDataSource.hasSelection = !collectionViewController.selectedIndexes.isEmpty
        toolbar.reloadButtons()
    }
    
    /// Which members should be contacted using the action buttons.
    func membersToContact() -> [Person] {
        let allMembers: [Person] = collectionViewController.membersOfGroup
        let selectedPeople = collectionViewController.selectedPeople.map { stateController.person(for: $0) }
        return isEditing ? selectedPeople : allMembers
    }
    
    public func actionButtonPressed(action: Action) {
        switch action {
        case .text:
            let controller = MFMessageComposeViewController()
            controller.messageComposeDelegate = modalListener
            let phoneNumbers = membersToContact().compactMap { $0.phoneNumber }
            controller.recipients = phoneNumbers.map { $0.rawValue }
            present(controller, animated: true, completion: nil)
        case .email:
            let controller = MFMailComposeViewController()
            controller.mailComposeDelegate = modalListener
            let emails = membersToContact().compactMap { $0.email }
            controller.setToRecipients(emails.map { $0.rawValue })
            present(controller, animated: true, completion: nil)
        case .remove:
            displayRemoveConfirmation()
        case .newGroup:
            guard let newGroup = stateController.createNewGroup(name: "Selection of \(group.name)", meta: GroupMeta(color: AssetCatalog.Color.groupColors.randomElement()!), members:  collectionViewController.selectedPeople) else {
                print("Failed to create new group from selection")
                #warning("Surface to user")
                return
            }
            stateController.move(group: newGroup.identifier, after: group.identifier)
            navigationController?.popViewController(animated: true)
        }
    }
    
    /// Display an alert controller that allows the user to cancel a remove operation or allow it to continue.
    func displayRemoveConfirmation() {
        let selectedCount = collectionViewController.selectedPeople.count
        let suffix = selectedCount == 1 ? "" : "s"
        let alertView = UIAlertController(title: "Remove \(selectedCount) contact\(suffix)?", message: "The contacts themselves will remain intact.", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .destructive) { [weak self] (action)  in
            guard let self = self else { return }
            self.removeMembersFromGroup()
        }
        let no = UIAlertAction(title: "No", style: .cancel) {_ in }
        alertView.addAction(yes)
        alertView.addAction(no)
        present(alertView, animated: true, completion: nil)
    }
    
    func removeMembersFromGroup() {
        stateController.remove(people: collectionViewController.selectedPeople, fromGroup: groupID)
        collectionViewController.removeSelectedItems()
    }
}
