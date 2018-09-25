//
//  StateController.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let stateDidChange = Notification.Name("StateControllerStateDidChange")
}

/// Manages the Group and Person state of the app.
/// Holds the authority of the current version of each group and person.
public class StateController {
    
    // Store unique identifier to group pairs.
    var groups: [Group.ID: Group] = [:]
    
    // Store unique identifier to person pairs.
    var people: [Person.ID: Person] = [:]
    
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
        refreshState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// A non-Optional wrapper for the subscript operation on `groups`.
    func group(forID identifier: Group.ID) -> Group {
        guard let group = groups[identifier] else {
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
        return person(forID: identifier).groupIDs.compactMap { groups[$0] }
    }
    
    /// The person objects for the memberIDs property of the group referenced by the given identifier.
    func members(ofGroup identifier: Group.ID) -> [Person] {
        return group(forID: identifier).memberIDs.compactMap { people[$0] }
    }
    
    /// Add the group. Currently only uses the name. In the future the color will be configurable that is why this is wrapping the call.
    func add(_ group: Group) throws {
        try contactsStoreWrapper.addGroup(named: group.name)
    }
    
    /// Link the person and the group together. Connects both directions. The private implementation of connecting a person to a group when they are added.
    private func link(person personID: Person.ID, toGroup groupID: Group.ID) {
        // Add the person as a member of the group.
        var group = self.group(forID: groupID)
        group.memberIDs.append(personID)
        groups[groupID] = group
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
    
    /// Removes the link between the person and the group. Disconnects both directions.
    func remove(person personID: Person.ID, fromGroup groupID: Group.ID) {
        /// Remove the person from the group.
        guard let personIndex = self.group(forID: groupID).memberIDs.firstIndex(of: personID) else {
            fatalError("Given person not a member of given group.")
        }
        var group = self.group(forID: groupID)
        group.memberIDs.remove(at: personIndex)
        groups[groupID] = group
        
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
    
    func refreshState() {
        do {
            groups = [:]
            people = [:]
            
            let fetchedGroups = try self.fetchGroups()
            for group in fetchedGroups {
                groups[group.identifier!] = group
                
                let peopleInGroup = try self.fetchPeople(in: group)
                
                // Add each person to this group.
                // Each person is guaranteed to have an identifier because they come straight from the contact store wrapper and the same for the group.
                for person in peopleInGroup {
                    // Only keep one instance of a Person.
                    if people[person.identifier!] == nil {
                        people[person.identifier!] = person
                    }
                    link(person: person.identifier!, toGroup: group.identifier!)
                }
            }
            NotificationCenter.default.post(name: .stateDidChange, object: self)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Gets the groups from the ContactStoreWrapper.
    private func fetchGroups() throws -> [Group]  {
        var colorIndex = 0
        
        let contactGroups = try self.contactsStoreWrapper.backingStore.groups(matching: nil)
        let groups = contactGroups.map { contactGroup -> Group in
            colorIndex += 1
            return Group(contactGroup, color: UIColor.color(for: colorIndex))
        }
        return groups
    }
    
    /// Gets the members of the given group from the ContactStoreWrapper.
    private func fetchPeople(in group: Group) throws -> [Person] {
        let contactsInGroup = try self.contactsStoreWrapper.backingStore.unifiedContacts(matching: group.containedContactsPredicate!, keysToFetch: Person.requiredContactKeys)
        
        return contactsInGroup.map(Person.init)
    }
}
