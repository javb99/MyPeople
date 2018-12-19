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
    
    var navigationCoordinator: AppNavigationCoordinator!
    var stateController: StateController!
    
    public init() {
        super.init(style: .plain)
        
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
        
        reloadDataSource()
        
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .scrollableAxes
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
        let groups = stateController.orderedGroupIDs.map { stateController.group(forID: $0) }
        groupCounts = []
        for group in groups {
            let count = stateController.members(ofGroup: group.identifier).count
            groupCounts.append(GroupCount(group: group, memberCount: count))
        }
        if reloadDisplay { tableView.reloadData() }
    }
    
    @objc func appStateDidChange() {
        reloadDataSource()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        let groupDetailController = navigationCoordinator.prepareGroupDetailViewController(for: group.identifier)
        navigationController?.pushViewController(groupDetailController, animated: true)
    }
    
    // MARK: Deletion and Reorder.
    
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let group = groupCounts[indexPath.row].group
            stateController.delete(group: group.identifier)
            reloadDataSource(reloadDisplay: false)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
