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
    
    public private(set) var accessState: AuthenticationResult?
    
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
    
    /// Executes the given code if currently authorized. Returns true if allowed.
    public func doIfAllowed(code: ()->()) -> Bool {
        if accessState == .success {
            code()
            return true
        } else {
            return false
        }
    }
    
    public func addGroup(named name: String) throws {
        let group = CNMutableGroup()
        group.name = name
        let saveRequest = CNSaveRequest()
        saveRequest.add(group, toContainerWithIdentifier: nil)
        do {
            try backingStore.execute(saveRequest)
        } catch {
            print(error.localizedDescription)
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
