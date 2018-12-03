//
//  GroupDetailViewController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 11/23/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

public class GroupDetailViewController: UIViewController {
    
    // MARK: Dependencies
    public var navigationCoordinator: AppNavigationCoordinator!
    public var stateController: StateController!
    public var groupID: Group.ID!
    
    // MARK: Instance members
    public var collectionViewController: GroupDetailCollectionViewController
    private var gradientView: GradientView
    private var actionButtonsView: ActionButtonsView
    
    private var group: Group!
    
    public init() {
        collectionViewController = GroupDetailCollectionViewController()
        gradientView = GradientView(frame: .zero)
        actionButtonsView = ActionButtonsView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let group = stateController.groupsTable[groupID] else {
            fatalError("Invalid groupID dependency")
        }
        self.group = group
        
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
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        var resetConfig = NavBarConfiguration()
        resetConfig.backgroundImage = .some(nil)
        resetConfig.barStyle = .default
        navigationController!.navigationBar.apply(resetConfig)
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
        actionButtonsView.actionPressedCallback = collectionViewController.actionButtonPressed
        actionButtonsView.buttonTint = group.meta.color
        view.addSubview(actionButtonsView)
    }
    
    /// Fill dependencies of the collectionViewController
    func configureCollectionViewController() {
        collectionViewController.navigationCoordinator = navigationCoordinator
        collectionViewController.stateController = stateController
        collectionViewController.groupID = groupID
        
        addChild(collectionViewController)
        view.addSubview(collectionViewController.view)
    }
    
    /// Set and activate the layout constraints. Views should already be added as subviews.
    func addConstraints() {
        guard collectionViewController.view.superview === view, gradientView.superview === view, actionButtonsView.superview === view else {
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
        
        actionButtonsView.usesAutoLayout()
        actionButtonsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        actionButtonsView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        let spaceBelowActionButtons: CGFloat = 6
        actionButtonsView.bottomAnchor.constraint(equalTo: collectionViewController.view.topAnchor, constant: -spaceBelowActionButtons).isActive = true
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
    }
}
