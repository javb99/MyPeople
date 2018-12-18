//
//  StateController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import Contacts

extension Notification.Name {
    static let stateDidChange = Notification.Name("StateControllerStateDidChange")
}

/// Manages the Group and Person state of the app.
/// Holds the authority of the current version of each group and person.
public class StateController {
    
    // Store unique identifier to group pairs.
    private(set) var groupsTable: [Group.ID: Group] = [:]
    
    // Store unique identifier to person pairs.
    private(set) var people: [Person.ID: Person] = [:]
    
    /// All the group IDs in a constant order. In the future this order will be changeable by the user.
    private(set) var orderedGroupIDs: [Group.ID] = []
    
    private(set) var needsToSave: Bool = false
    
    /// Used when adding a group to avoid a race condition that prohibits using user defined meta.
    private(set) var shouldReloadOnCNStoreChange: Bool = true
    
    private var contactsStoreWrapper: ContactStoreWrapper
    
    init(contactsStoreWrapper: ContactStoreWrapper) {
        self.contactsStoreWrapper = contactsStoreWrapper
        switch contactsStoreWrapper.authorizationStatus {
        case .notDetermined:
            contactsStoreWrapper.requestAccess { (result) in
                guard result == .success else { return }
                DispatchQueue.main.async {
                    self.refreshState()
                }
            }
        case .authorized:
            refreshState()
        case .restricted, .denied:
            print("Could not fetch state because contacts access is blocked.")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(contactStoreDidChange), name: Notification.Name.CNContactStoreDidChange, object: nil)
    }
    
    @objc func contactStoreDidChange() {
        if shouldReloadOnCNStoreChange {
            refreshState()
        } else {
            print("Refresh ignored.")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Return the given groups ordered according to the order of `orderedGroupIDs`.
    func order(_ groupIDs: [Group.ID]) -> [Group.ID] {
        return groupIDs.sorted { orderedGroupIDs.does($0, appearBefore: $1) }
        //return orderedGroupIDs.intersection(groups)
    }
    
    /// A non-Optional wrapper for the subscript operation on `groups`.
    func group(forID identifier: Group.ID) -> Group {
        guard let group = groupsTable[identifier] else {
            fatalError("No group identified by groupID")
        }
        return group
    }
    
    /// A non-Optional wrapper for the subscript operation on `people`.
    func person(forID identifier: Person.ID) -> Person {
        guard let person = people[identifier] else {
            fatalError("No person identified by personID")
        }
        return person
    }
    
    /// The group objects for the groupIDs property of the person referenced by the given identifier.
    func groups(forPerson identifier: Person.ID) -> [Group] {
        return person(forID: identifier).groupIDs.compactMap { groupsTable[$0] }
    }
    
    /// The person objects for the memberIDs property of the group referenced by the given identifier.
    func members(ofGroup identifier: Group.ID) -> [Person] {
        return group(forID: identifier).memberIDs.compactMap { people[$0] }
    }
    
    /// Add the group. Currently only uses the name. In the future the color will be configurable that is why this is wrapping the call.
    @discardableResult
    func createNewGroup(_ name: String, meta: GroupMeta) -> Group? {
        let incomingValue = shouldReloadOnCNStoreChange
        defer {
            print("Defer statement")
            shouldReloadOnCNStoreChange = incomingValue
        }
        do {
            shouldReloadOnCNStoreChange = false
            let cnGroup = try contactsStoreWrapper.addGroup(named: name)
            print("New Group created.")
            let group = Group(cnGroup, meta: meta)
            rememberGroup(group)
            NotificationCenter.default.post(name: .stateDidChange, object: self)
            saveGroupsToDisk()
            return group
        } catch {
            print("Failed to create new group: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Link the person and the group together. Connects both directions. The private implementation of connecting a person to a group when they are added.
    private func link(person personID: Person.ID, toGroup groupID: Group.ID) {
        // Add the person as a member of the group.
        var group = self.group(forID: groupID)
        group.memberIDs.append(personID)
        groupsTable[groupID] = group
        // Add the group to the person's groupIDs array.
        var person = self.person(forID: personID)
        person.groupIDs.append(groupID)
        people[personID] = person
    }
    
    /// Add the person to the group.
    public func add(person personID: Person.ID, toGroup groupID: Group.ID) {
        do {
            try contactsStoreWrapper.addContact(identifiedBy: personID.rawValue, toGroupIdentifiedBy: groupID.rawValue)
            link(person: personID, toGroup: groupID)
        } catch {
            print("Failed to add person")
        }
    }
    
    /// Add the people to the group.
    public func add(people peopleIDs: [Person.ID], toGroup groupID: Group.ID) {
        for person in peopleIDs {
            add(person: person, toGroup: groupID)
        }
    }
    
    /// Removes the link between the person and the group. Disconnects both directions.
    func remove(person personID: Person.ID, fromGroup groupID: Group.ID) {
        /// Remove the person from the group.
        guard let personIndex = self.group(forID: groupID).memberIDs.firstIndex(of: personID) else {
            fatalError("Given person not a member of given group.")
        }
        var group = self.group(forID: groupID)
        group.memberIDs.remove(at: personIndex)
        groupsTable[groupID] = group
        
        /// Remove the group from the person's groupIDs array.
        guard let groupIndex = self.person(forID: personID).groupIDs.firstIndex(of: groupID) else {
            fatalError("Given person not a member of given group.")
        }
        var person = self.person(forID: personID)
        person.groupIDs.remove(at: groupIndex)
        people[personID] = person
    }
    
    func delete(group identifier: Group.ID) {
        // TODO: implement
    }
    
    private func rememberGroup(_ group: Group) {
        groupsTable[group.identifier] = group
        orderedGroupIDs.append(group.identifier)
    }
    
    func refreshState() {
        do {
            saveIfNeeded()
            
            groupsTable = [:]
            people = [:]
            orderedGroupIDs = []
            
            let fetchedGroups = try self.fetchGroups()
            for group in fetchedGroups {
                rememberGroup(group)
                
                let peopleInGroup = try self.fetchPeople(in: group)
                
                // Add each person to this group.
                for person in peopleInGroup {
                    // Only keep one instance of a Person.
                    if people[person.identifier] == nil {
                        people[person.identifier] = person
                    }
                    link(person: person.identifier, toGroup: group.identifier)
                }
            }
            NotificationCenter.default.post(name: .stateDidChange, object: self)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Creates a GroupMeta value for the CNGroup. The return value will be the same everytime it is called with the same CNGroup.
    private func createGroupMeta(for cnGroup: CNGroup) -> GroupMeta {
        let colors = AssetCatalog.Color.groupColors
        let color = colors[abs(cnGroup.identifier.hashValue) % colors.count]
        return GroupMeta(color: color)
    }
    
    /// Gets the members of the given group from the ContactStoreWrapper.
    private func fetchPeople(in group: Group) throws -> [Person] {
        let contactsInGroup = try self.contactsStoreWrapper.backingStore.unifiedContacts(matching: group.containedContactsPredicate, keysToFetch: Person.requiredContactKeys)
        
        return contactsInGroup.map(Person.init)
    }
    
    /// Gets the `CNGroup`s from the `ContactStoreWrapper` and the `Group`s stored locally on disk and matches them up creating new `Group`s as needed. Returns the groups sorted according to the stored order if any.
    private func fetchGroups() throws -> [Group]  {
        let groupStorage = try? GroupStorage.loadFromDisk()
        
        let contactGroups = try self.contactsStoreWrapper.backingStore.groups(matching: nil)
        var groups = contactGroups.map { contactGroup -> Group in
            let id = Group.ID(rawValue: contactGroup.identifier)
            
            // Use a stored group meta or create a new one.
            var groupMeta: GroupMeta
            if let meta = groupStorage?.groupMetas[id] {
                groupMeta = meta
            } else {
                print("Created a new GroupMeta for \"\(contactGroup.name)\" (\(contactGroup.identifier))")
                groupMeta = createGroupMeta(for: contactGroup)
                needsToSave = true
            }
            return Group(contactGroup, meta: groupMeta)
        }
        // Sort if order was stored.
        if let order = groupStorage?.groupOrder {
            groups.sort { order.does($0.identifier, appearBefore: $1.identifier) }
        }
        return groups
    }
    
    public func saveIfNeeded() {
        if needsToSave {
            saveGroupsToDisk()
        }
    }
    
    private func saveGroupsToDisk() {
        let groupMetas = Dictionary(uniqueKeysWithValues: groupsTable.map({ (key, value) -> (Group.ID, GroupMeta) in
            return (key, value.meta)
        }))
        let groupStorage = GroupStorage(groupOrder: orderedGroupIDs, groupMetas: groupMetas)
        groupStorage.saveToDisk()
        needsToSave = false
    }
}



private struct GroupStorage: Codable {
    let groupMetas: [Group.ID: GroupMeta]
    let groupOrder: [Group.ID]
    
    init(groupOrder: [Group.ID], groupMetas: [Group.ID: GroupMeta]) {
        self.groupOrder = groupOrder
        self.groupMetas = groupMetas
    }
    
    /// URL to store the groups json file at.
    private static let groupsURL: URL = {
        let documentDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDir = documentDirs[0]
        return documentDir.appendingPathComponent("StateController_groups").appendingPathExtension("json")
    }()
    
    /// Could fail and throw an error while reading from the file and decoding the data.
    static func loadFromDisk() throws -> GroupStorage {
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: GroupStorage.groupsURL)
        let groups: GroupStorage = try decoder.decode(GroupStorage.self, from: data)
        return groups
    }
    
    func saveToDisk() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            try data.write(to: GroupStorage.groupsURL)
            print("Saved groups to \(GroupStorage.groupsURL.absoluteString)")
        } catch {
            print("Error saving groups to disk: \(error.localizedDescription)")
        }
    }
}

extension Array where Element: Equatable {
    /// Complexity: O(n)
    func does(_ a: Element, appearBefore b: Element) -> Bool {
        for element in self {
            if element == a {
                return true
            } else if element == b {
                return false
            }
        }
        assertionFailure("Neither element is contained.")
        return false
    }
}
