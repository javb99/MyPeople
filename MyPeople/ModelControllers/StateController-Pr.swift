//
//  StateController-Pr.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 1/26/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

public protocol StateController {
    
    // MARK: Getters
    
    /// All the group IDs in a constant order. In the future this order will be changeable by the user.
    var orderedGroupIDs: [Group.ID] { get }
    
    /// Return the given groups ordered according to the order of `orderedGroupIDs`.
    func order<Col: Sequence>(_ groupIDs: Col) -> [Group.ID] where Col.Element == Group.ID
    
    /// A non-Optional wrapper for the subscript operation on `groups`.
    func group(for identifier: Group.ID) -> Group
    
    /// A non-Optional wrapper for the subscript operation on `people`. Also tries to fetch the person if there is no person stored in memory for that identifier.
    func person(for identifier: Person.ID) -> Person
    
    /// The group objects for the groupIDs property of the person referenced by the given identifier.
    func groups(forPerson identifier: Person.ID) -> [Group]
    
    /// The person objects for the memberIDs property of the group referenced by the given identifier.
    func members(ofGroup identifier: Group.ID) -> [Person]
    
    // MARK: Operations
    
    /// Add the group in the system, in memory, and on disk. Currently only uses the name. In the future the color will be configurable.
    @discardableResult func createNewGroup(name: String, meta: GroupMeta) -> Group?
    
    /// Add the group in the system, in memory, and on disk. Currently only uses the name. In the future the color will be configurable.
    @discardableResult func createNewGroup(name: String, meta: GroupMeta, members: [Person.ID]) -> Group?
    
    /// Add the person to the group. In memory and in the system.
    func add(person personID: Person.ID, toGroup groupID: Group.ID)
    
    /// Add the people to the group. In memory and in the system. A convience wrapper around `add(person:toGroup:)`.
    func add(people peopleIDs: [Person.ID], toGroup groupID: Group.ID)
    
    func remove(person personID: Person.ID, fromGroup groupID: Group.ID)
    
    func remove(people peopleIDs: [Person.ID], fromGroup groupID: Group.ID)
    
    /// Delete the group from the contact store.
    func delete(group identifier: Group.ID)
    
    /// Create a copy of the group with the same meta and the same name with " - Copy" appended. All the members are added to the copy.
    @discardableResult func duplicate(group identifier: Group.ID) -> Group?
    
    /// Position the movingID directly following the referenceID in orderedGroupIDs.
    func move(group movingID: Group.ID, after referenceID: Group.ID)
    
    /// Save the in-memory state to disk if there are changes to save. Does nothing if `needsToSave` is false.
    func saveIfNeeded()
}
