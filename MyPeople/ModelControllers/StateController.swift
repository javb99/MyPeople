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
    // MARK: Core State
    
    // Store unique identifier to group pairs.
    private(set) var groupsTable: [Group.ID: Group] = [:]
    
    // Store unique identifier to person pairs.
    private(set) var people: [Person.ID: Person] = [:]
    
    /// All the group IDs in a constant order. In the future this order will be changeable by the user.
    private(set) var orderedGroupIDs: [Group.ID] = []
    
    // MARK: Other Properties
    
    /// True if there are changes that need to be saved to disk.
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
            #warning("Needs a strategy to inform user.")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(contactStoreDidChange), name: Notification.Name.CNContactStoreDidChange, object: nil)
    }
    
    @objc func contactStoreDidChange() {
        if shouldReloadOnCNStoreChange {
            refreshState()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface -
    
    // MARK: Getters
    
    /// Return the given groups ordered according to the order of `orderedGroupIDs`.
    func order(_ groupIDs: [Group.ID]) -> [Group.ID] {
        return groupIDs.sorted { orderedGroupIDs.does($0, appearBefore: $1) }
    }
    
    /// A non-Optional wrapper for the subscript operation on `groups`.
    func group(for identifier: Group.ID) -> Group {
        guard let group = groupsTable[identifier] else {
            fatalError("No group identified by groupID")
        }
        return group
    }
    
    /// A non-Optional wrapper for the subscript operation on `people`.
    func person(for identifier: Person.ID) -> Person {
        guard let person = people[identifier] else {
            fatalError("No person identified by personID")
        }
        return person
    }
    
    /// The group objects for the groupIDs property of the person referenced by the given identifier.
    func groups(forPerson identifier: Person.ID) -> [Group] {
        return person(for: identifier).groupIDs.compactMap { groupsTable[$0] }
    }
    
    /// The person objects for the memberIDs property of the group referenced by the given identifier.
    func members(ofGroup identifier: Group.ID) -> [Person] {
        return group(for: identifier).memberIDs.compactMap { people[$0] }
    }
    
    // MARK: Operations
    
    /// Add the group in the system, in memory, and on disk. Currently only uses the name. In the future the color will be configurable.
    @discardableResult
    func createNewGroup(_ name: String, meta: GroupMeta) -> Group? {
        return ignoreReloadDuring { p_createNewGroup(name, meta: meta) }
    }
    
    /// Add the person to the group. In memory and in the system.
    public func add(person personID: Person.ID, toGroup groupID: Group.ID) {
        do {
            var person: Person
            if let p = people[personID] {
                person = p
                
            } else {
                print("Person wasn't loaded in memory. Fetching them.")
                guard let p = try contactsStoreWrapper.fetchPerson(identifiedBy: personID) else {
                    fatalError("Unable to fetch the person to add them to a group. This shouldn't happen because the person was selected from a list of contacts.")
                }
                rememberPerson(p)
                person = p
            }
            // Creates the relationship in the system contact store.
            try contactsStoreWrapper.addContact(person, to: group(for: groupID))
            // Create the relationship in memory.
            link(person: personID, toGroup: groupID)
        } catch {
            print("Failed to add person")
        }
    }
    
    /// Add the people to the group. In memory and in the system. A convience wrapper around `add(person:toGroup:)`.
    public func add(people peopleIDs: [Person.ID], toGroup groupID: Group.ID) {
        for person in peopleIDs {
            add(person: person, toGroup: groupID)
        }
    }
    
    /// Delete the group from the contact store.
    public func delete(group identifier: Group.ID) {
        ignoreReloadDuring {
            // Remove from the system contacts store.
            contactsStoreWrapper.deleteGroup(group(for: identifier))
            // Remove from in memory storage
            groupsTable[identifier] = nil
            orderedGroupIDs.removeAll(where: { $0 == identifier })
            // Save changes to disk.
            needsToSave = true
            saveIfNeeded()
        }
    }
    
    /// Save the in-memory state to disk if there are changes to save. Does nothing if `needsToSave` is false.
    public func saveIfNeeded() {
        if needsToSave {
            saveGroupsToDisk()
        }
    }
    
    /// Stops the reload due to a CNStoreChange notification during the execution of the given code. Returns the return value of the code block untouched.
    public func ignoreReloadDuring<Return>(_ code: ()->Return) -> Return{
        let incomingValue = shouldReloadOnCNStoreChange
        defer {
            shouldReloadOnCNStoreChange = incomingValue
        }
        shouldReloadOnCNStoreChange = false
        return code()
    }
    
    // MARK: - Implementation -
    
    /// Link the person and the group together in-memory. Connects both directions. The private implementation of connecting a person to a group when they are added.
    private func link(person personID: Person.ID, toGroup groupID: Group.ID) {
        // Add the person as a member of the group.
        var group = self.group(for: groupID)
        group.memberIDs.append(personID)
        groupsTable[groupID] = group
        // Add the group to the person's groupIDs array.
        var person = self.person(for: personID)
        person.groupIDs.append(groupID)
        people[personID] = person
    }
    
    /// Removes the in-memory link between the person and the group. Disconnects both directions.
    private func remove(person personID: Person.ID, fromGroup groupID: Group.ID) {
        /// Remove the person from the group.
        guard let personIndex = self.group(for: groupID).memberIDs.firstIndex(of: personID) else {
            fatalError("Given person not a member of given group.")
        }
        var group = self.group(for: groupID)
        group.memberIDs.remove(at: personIndex)
        groupsTable[groupID] = group
        
        /// Remove the group from the person's groupIDs array.
        guard let groupIndex = self.person(for: personID).groupIDs.firstIndex(of: groupID) else {
            fatalError("Given person not a member of given group.")
        }
        var person = self.person(for: personID)
        person.groupIDs.remove(at: groupIndex)
        people[personID] = person
    }
    
    /// Implementation. Don't call this. call `createNewGroup(_:meta:)` instead. That method wraps this method in an ignoreReloadDuring block.
    private func p_createNewGroup(_ name: String, meta: GroupMeta) -> Group? {
        do {
            // Add to system contacts store.
            let cnGroup = try contactsStoreWrapper.addGroup(named: name)
            // Add in memory.
            let group = Group(cnGroup, meta: meta)
            rememberGroup(group)
            //NotificationCenter.default.post(name: .stateDidChange, object: self)
            // Save to disk.
            needsToSave = true
            saveIfNeeded()
            return group
        } catch {
            print("Failed to create new group: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Adds the person in memory. Doesn't save the change to disk.
    private func rememberPerson(_ person: Person) {
        people[person.identifier] = person
    }
    
    /// Adds the group in memory. Doesn't save the change to disk.
    private func rememberGroup(_ group: Group) {
        groupsTable[group.identifier] = group
        orderedGroupIDs.append(group.identifier)
    }
    
    /// Used to keep in sync with the system contact store.
    private func refreshState() {
        do {
            saveIfNeeded()
            
            groupsTable = [:]
            people = [:]
            orderedGroupIDs = []
            
            let fetchedGroups = try self.fetchGroups()
            for group in fetchedGroups {
                rememberGroup(group)
                
                let peopleInGroup = try contactsStoreWrapper.fetchPeople(in: group)
                
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
    
    /// Gets the `CNGroup`s from the `ContactStoreWrapper` and the `Group`s stored locally on disk and matches them up creating new `Group`s as needed. Returns the groups sorted according to the stored order if any.
    private func fetchGroups() throws -> [Group]  {
        let groupStorage = try? GroupStorage.loadFromDisk()
        
        let contactGroups = try self.contactsStoreWrapper.allGroups()
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
    
    /// Don't call directly. Set `needsToSave` to true then call `saveIfNeeded()`.
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
