//
//  MyPeopleNavigationCoordinator.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

public protocol AppNavigationCoordinator: class {
    func prepareMyPeopleViewController() -> UIViewController
    func prepareGroupDetailViewController(for groupID: Group.ID) -> UIViewController?
    func prepareContactDetailViewController(forContactIdentifiedBy identifier: String) throws -> UIViewController
}

/// Holds the depencencies of the ViewControllers and loads them into view controllers.
public class MyPeopleNavigationCoordinator: AppNavigationCoordinator {
    
    var contactsStoreWrapper: ContactStoreWrapper
    var stateController: StateController
    
    public init() {
        contactsStoreWrapper = ContactStoreWrapper()
        stateController = StateController(contactsStoreWrapper: contactsStoreWrapper)
    }
    
    public func prepareMyPeopleViewController() -> UIViewController {
        let controller = MyPeopleViewController(navigationCoordinator: self, stateController: stateController)
        return controller
    }
    
    public func prepareGroupDetailViewController(for groupID: Group.ID) -> UIViewController? {
        let controller = GroupDetailViewController(navigationCoordinator: self, stateController: stateController, groupID: groupID)
        return controller
    }
    
    /// Throws an error if authorization is denied or rethrows any error that is encountered while fetching the contact.
    public func prepareContactDetailViewController(forContactIdentifiedBy identifier: String) throws -> UIViewController {
        
        guard contactsStoreWrapper.authorizationStatus == .authorized else {
            throw CNError(.authorizationDenied)
        }
        
        let store = contactsStoreWrapper.backingStore
        do {
            let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
            let controller = CNContactViewController(for: contact)
            controller.allowsEditing = false
            return controller
            
        } catch {
            throw error
        }
    }
}
