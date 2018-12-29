//
//  ContactStore
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/15/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import Contacts

public protocol HighLevelConstactStore: class {
    var authorizationStatus: CNAuthorizationStatus { get }
    func requestAccess(callback: @escaping (AuthenticationResult)->())
    /// Fetch all the groups.
    func allGroups() throws -> [CNGroup]
    func fetchPerson(identifiedBy identifier: Person.ID) throws -> Person?
    func fetchPerson(identifiedBy identifier: Person.ID, keysToFetch: [CNKeyDescriptor]) throws -> Person?
    /// Gets the members of the given group.
    func fetchPeople(in group: Group) throws -> [Person]
    /// Throws an error to signal failure.
    func addGroup(named name: String) throws -> CNGroup
    /// Remove the group from the contact store. If the group doesn't exist the operation will fail silently.
    func deleteGroup(_ group: Group)
    func addContact(_ person: Person, to group: Group) throws
    func remove(_ person: Person, from group: Group) throws
}

public enum AuthenticationResult: Equatable {
    case success
    case failed(Error)
    
    /// Return true if both operands are the same case. Ignores associated values.
    public static func ==(lhs: AuthenticationResult, rhs: AuthenticationResult) -> Bool {
        switch lhs {
        case .success:
            switch rhs {
            case .success:
                return true
            case .failed(_):
                return false
            }
        case .failed(_):
            switch rhs {
            case .success:
                return false
            case .failed(_):
                return true
            }
        }
    }
}

public class ContactStore: HighLevelConstactStore {
    
    public let backingStore: CNContactStore
    
    init() {
        backingStore = CNContactStore()
    }
    
    public var authorizationStatus: CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    public func requestAccess(callback: @escaping (AuthenticationResult)->()) {
        backingStore.requestAccess(for: .contacts) { (granted, error) in
            var result: AuthenticationResult
            if granted {
                result = .success
            } else {
                result = .failed(error!)
            }
            callback(result)
        }
    }
    
    public func allGroups() throws -> [CNGroup] {
        return try backingStore.groups(matching: nil)
    }
    
    public func fetchPerson(identifiedBy identifier: Person.ID, keysToFetch: [CNKeyDescriptor]) throws -> Person? {
        guard let contact = try backingStore.unifiedContacts(matching: Person.predicate(for: identifier), keysToFetch: keysToFetch).first else {
            return nil
        }
        return Person(contact)
    }
    
    public func fetchPerson(identifiedBy identifier: Person.ID) throws -> Person? {
        return try fetchPerson(identifiedBy: identifier, keysToFetch: Person.requiredContactKeys)
    }
    
    public func fetchPeople(in group: Group) throws -> [Person] {
        let contactsInGroup = try backingStore.unifiedContacts(matching: group.containedContactsPredicate, keysToFetch: Person.requiredContactKeys)
        
        return contactsInGroup.map(Person.init)
    }
    
    public func addGroup(named name: String) throws -> CNGroup {
        let group = CNMutableGroup()
        group.name = name
        let saveRequest = CNSaveRequest()
        saveRequest.add(group, toContainerWithIdentifier: nil)
        try backingStore.execute(saveRequest)
        return group
    }
    
    public func deleteGroup(_ group: Group) {
        let saveRequest = CNSaveRequest()
        let mutgroup = group.cnGroup.mutableCopy() as! CNMutableGroup
        saveRequest.delete(mutgroup)
        do {
            try backingStore.execute(saveRequest)
        } catch CNError.recordDoesNotExist {
            print("Group doesn't exist to delete. Continuing as if it has been deleted.")
        } catch {
            fatalError("Unexpected error while deleting group: \(error)")
        }
    }
    
    public func addContact(_ person: Person, to group: Group) throws {
        let saveRequest = CNSaveRequest()
        saveRequest.addMember(person.cnContact, to: group.cnGroup)
        try backingStore.execute(saveRequest)
    }
    
    public func remove(_ person: Person, from group: Group) throws {
        let saveRequest = CNSaveRequest()
        saveRequest.removeMember(person.cnContact, from: group.cnGroup)
        try backingStore.execute(saveRequest)
    }
}
