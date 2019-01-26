//
//  NewGroupViewController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 1/22/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions
import ContactsUI

extension NavBarConfiguration {
    /// Slate tint color on a light bar.
    public static var slateTint: NavBarConfiguration {
        var config = NavBarConfiguration.darkText
        config.tintColor = AssetCatalog.color(.slate)
        return config
    }
}

class NewGroupViewController: UIViewController {
    
    // MARK: Dependencies
    public var navigationCoordinator: AppNavigationCoordinator
    public var stateController: StateController
    
    // MARK: View Hiearchy References
    private var membersViewController: PeopleViewController
    private var colorPickerViewController: ColorPickerViewController
    private var nameField: UITextField
    
    // MARK: Instance Variables
    public var colorName: AssetCatalog.Color {
        didSet {
            let color = AssetCatalog.color(colorName)
            membersViewController.tintColor = color
            view.backgroundColor = color
        }
    }
    public private(set) var initialMemberIDs: [Person.ID] {
        didSet {
            let members = initialMemberIDs.map { stateController.person(for: $0) }
            membersViewController.setPeople(members)
        }
    }

    public init(navigationCoordinator: AppNavigationCoordinator, stateController: StateController, initialMemberIDs: [Person.ID] = []) {
        self.navigationCoordinator = navigationCoordinator
        self.stateController = stateController
        self.initialMemberIDs = initialMemberIDs
        colorName = .slate
        
        membersViewController = PeopleViewController(navigationCoordinator: navigationCoordinator, stateController: stateController)
        colorPickerViewController = ColorPickerViewController()
        
        nameField = UITextField()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "New Group"
        navigationItem.prompt = "Enter a name and choose a color."
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneButton
        navigationItem.leftBarButtonItem = cancelButton
        
        configureMembersViewController()
        configureColorPicker()
        
        nameField.placeholder = "Group Name"
        nameField.borderStyle = .roundedRect
        nameField.font = UIFont.preferredFont(forTextStyle: .headline)
        view.addSubview(nameField)
        
        colorName = .slate
        
        addConstraints()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// Change the nav bar appearance.
        self.navigationController!.navigationBar.apply(.slateTint)
    }
    
    @IBAction func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done() {
        guard let name = nameField.text, !name.isEmpty else {
            #warning("Lift to user")
            return
        }
        let meta = GroupMeta(color: colorName)
        stateController.createNewGroup(name: name, meta: meta, members: initialMemberIDs)
        dismiss(animated: true, completion: nil)
    }
    
    /// Fill dependencies of the collectionViewController
    func configureMembersViewController() {
        membersViewController.contactPickerDelegate = self
        addChild(membersViewController)
        view.addSubview(membersViewController.view)
        
        membersViewController.collectionView.numberOfItems(inSection: 0) // Avoid an internal inconsistency by allowing the insertion to be animated.
        membersViewController.isEditing = true
    }
    
    /// Fill dependencies of the configureColorPicker
    func configureColorPicker() {
        addChild(colorPickerViewController)
        view.addSubview(colorPickerViewController.view)
        colorPickerViewController.delegate = self
    }
    
    /// Set and activate the layout constraints. Views should already be added as subviews.
    func addConstraints() {
        guard membersViewController.view.superview === view, colorPickerViewController.view.superview === view else {
            fatalError("Subviews were not added before constraints.")
        }
        
        let colorPickerView: UIView = colorPickerViewController.view
        colorPickerView.usesAutoLayout()
        
        let membersView: UIView = membersViewController.view
        membersView.usesAutoLayout()
        
        nameField.usesAutoLayout()
        nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80).isActive = true
        nameField.constrain(\UIView.leadingAnchor, to: view, constant: 80)
        nameField.constrain(\UIView.trailingAnchor, to: view, constant: -80)
        
        colorPickerView.constrain(\UIView.leadingAnchor, to: view)
        colorPickerView.constrain(\UIView.trailingAnchor, to: view)
        colorPickerView.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 80).isActive = true
        colorPickerView.heightAnchor.constraint(equalToConstant: colorPickerViewController.preferredContentSize.height).isActive = true
        
        colorPickerView.bottomAnchor.constraint(equalTo: membersView.topAnchor).isActive = true
        
        membersView.constrain(\UIView.leadingAnchor, to: view)
        membersView.constrain(\UIView.trailingAnchor, to: view)
        membersView.constrain(\UIView.bottomAnchor, to: view)
    }
}

extension NewGroupViewController: ColorPickerDelegate {
    func colorPicker(_ picker: ColorPickerViewController, didSelect color: AssetCatalog.Color) {
        colorName = color
    }
}

extension NewGroupViewController: CNContactPickerDelegate {
    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let people = contacts.map { Person.ID(rawValue: $0.identifier) }
        initialMemberIDs.append(contentsOf: people)
        picker.dismiss(animated: true, completion: nil)
    }
}
