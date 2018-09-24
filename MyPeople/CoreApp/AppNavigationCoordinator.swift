//
//  AppNavigationCoordinator.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

/// Holds the depencencies of the ViewControllers and loads them into view controllers.
public class AppNavigationCoordinator: NSObject {
    
    var contactsStoreWrapper: ContactStoreWrapper
    var stateController: StateController
    
    public override init() {
        contactsStoreWrapper = ContactStoreWrapper()
        stateController = StateController(contactsStoreWrapper: contactsStoreWrapper)
    }
    
    public func prepareMyPeopleViewController() -> MyPeopleViewController {
        let controller = MyPeopleViewController()
        controller.navigationCoordinator = self
        controller.stateController = stateController
        return controller
    }
    
    public func prepareGroupDetailViewController(for groupID: String) -> GroupDetailViewController {
        let controller = GroupDetailViewController()
        controller.navigationCoordinator = self
        controller.stateController = stateController
        controller.groupID = groupID
        return controller
    }
    
    public func prepareContactDetailViewController(forContactIdentifiedBy identifier: String) throws -> CNContactViewController {
        
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
