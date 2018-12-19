//
//  ContactStoreWrapper.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/15/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import Contacts

public class ContactStoreWrapper {
    
    public let backingStore: CNContactStore
    
    init() {
        backingStore = CNContactStore()
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
    
    /// Throws an error to signal failure.
    public func addGroup(named name: String) throws -> CNGroup {
        let group = CNMutableGroup()
        group.name = name
        let saveRequest = CNSaveRequest()
        saveRequest.add(group, toContainerWithIdentifier: nil)
        try backingStore.execute(saveRequest)
        return group
    }
    
    /// Remove the group from the contact store. If the group doesn't exist the operation will fail silently.
    public func deleteGroup(_ groupID: Group.ID) {
        let saveRequest = CNSaveRequest()
        let pred = CNGroup.predicateForGroups(withIdentifiers: [groupID.rawValue])
        guard let group = (try? backingStore.groups(matching: pred))?.first else {
            print("Could not find the group to delete it. Continuing as if it has been deleted.")
            return
        }
        
        let mutgroup = group.mutableCopy() as! CNMutableGroup
        saveRequest.delete(mutgroup)
        do {
            try backingStore.execute(saveRequest)
        } catch CNError.recordDoesNotExist {
            print("Group doesn't exist to delete. Continuing as if it has been deleted.")
        } catch {
            fatalError("Unexpected error while deleting group: \(error)")
        }
    }
    
    public func addContact(identifiedBy personIdentifier: String, toGroupIdentifiedBy groupIdentifier: String) throws {
        guard let group = try backingStore.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [groupIdentifier])).first else {
            fatalError("Could not fetch Group.")
        }
        let contact = try backingStore.unifiedContact(withIdentifier: personIdentifier, keysToFetch: [])
        let saveRequest = CNSaveRequest()
        saveRequest.addMember(contact, to: group)
        try backingStore.execute(saveRequest)
    }
    
    public func addContacts(identifiedBy identifiers: [String], toGroupIdentifiedBy groupIdentifier: String) {
        
        
        
    }
}
