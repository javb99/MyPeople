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

public class MyPeopleViewController: UITableViewController {
    
    // MARK: Static Members
    
    static let cellIdentifier: String = "GroupCell"
    
    // MARK: Instance Members
    
    var groupCounts = [GroupCount]()
    
    // MARK: Dependencies
    
    var navigationCoordinator: AppNavigationCoordinator
    var stateController: StateController
    
    public init(navigationCoordinator: AppNavigationCoordinator, stateController: StateController) {
        self.navigationCoordinator = navigationCoordinator
        self.stateController = stateController
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "My People"
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newGroupButtonPressed(_:)))
        navigationItem.setRightBarButton(addButton, animated: false)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 46.7
        
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.register(GroupCell.self, forCellReuseIdentifier: MyPeopleViewController.cellIdentifier)
    }
    
    func navBarConfig() -> NavBarConfiguration {
        var config = NavBarConfiguration()
        config.shadowImage = .some(nil)
        config.tintColor = .black
        config.barTintColor = .white
        config.barStyle = .default
        config.isTranslucent = true
        config.backgroundImage = .some(nil)
        return config
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if animated {
            transitionCoordinator!.animate(alongsideTransition: { (context) in
                self.navigationController!.navigationBar.apply(self.navBarConfig())
            }, completion: nil)
        } else {
            self.navigationController!.navigationBar.apply(self.navBarConfig())
        }
        
        reloadDataSource()
    }
    
    struct GroupCount {
        let group: Group
        let memberCount: Int
    }
    
    func reloadDataSource(reloadDisplay: Bool = true) {
        let groups = stateController.orderedGroupIDs.map { stateController.group(for: $0) }
        groupCounts = []
        for group in groups {
            let count = stateController.members(ofGroup: group.identifier).count
            groupCounts.append(GroupCount(group: group, memberCount: count))
        }
        if reloadDisplay { tableView.reloadData() }
    }
    
    @IBAction func newGroupButtonPressed(_ button: UIButton?) {
        let alertView = UIAlertController(title: "New Group", message: "Enter a group name", preferredStyle: .alert)
        alertView.addTextField(configurationHandler: nil)
        let done = UIAlertAction(title: "Add", style: .default) { [weak self] (action)  in
            guard let self = self else { return }
            let textField = alertView.textFields!.first!
            guard let text = textField.text, !text.isEmpty else { fatalError() }
            self.stateController.createNewGroup(name: text, meta: GroupMeta(color: AssetCatalog.Color.groupColors.randomElement()!))
            // Insert the row at the end.
            self.reloadDataSource(reloadDisplay: false)
            let count = self.groupCounts.count
            let indexPath = IndexPath(row: count-1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertView.addAction(done)
        alertView.addAction(cancel)
        present(alertView, animated: true, completion: nil)
    }
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupCounts.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MyPeopleViewController.cellIdentifier) as? GroupCell else {
            fatalError("Could not deque a group cell.")
        }
        
        let groupCount = groupCounts[indexPath.row]
        cell.title = groupCount.group.name
        cell.color = groupCount.group.meta.color
        cell.memberCount = groupCount.memberCount
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = groupCounts[indexPath.row].group
        // Unwrapped because I know this group id is safe. It come from a list of groups from the stateController.
        let groupDetailController = navigationCoordinator.prepareGroupDetailViewController(for: group.identifier)!
        navigationController?.pushViewController(groupDetailController, animated: true)
    }
    
    // MARK: Deletion and Reorder.
    
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (_, indexPath) in
            self?.deleteGroup(at: indexPath)
        }
        let duplicate = UITableViewRowAction(style: .normal, title: "Duplicate") { [weak self] (_, indexPath) in
            self?.duplicateGroup(at: indexPath)
        }
        return [duplicate, delete]
    }
    
    public func deleteGroup(at indexPath: IndexPath) {
        let group = groupCounts[indexPath.row].group
        stateController.delete(group: group.identifier)
        reloadDataSource(reloadDisplay: false)
        tableView.deleteRows(at: [indexPath], with: .none)
    }
    
    public func duplicateGroup(at indexPath: IndexPath) {
        let group = groupCounts[indexPath.row].group
        guard let _ = self.stateController.duplicate(group: group.identifier) else {
            fatalError("Failed to duplicate group")
        }
        print("About to insert.")
        self.reloadDataSource(reloadDisplay: false)
        let dupIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        tableView.insertRows(at: [dupIndexPath], with: .top)
    }
}
