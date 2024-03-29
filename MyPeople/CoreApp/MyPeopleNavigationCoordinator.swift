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
    func prepareNewGroupViewController(withInitialMembers: [Person.ID]) -> UIViewController
    func prepareGroupDetailViewController(for groupID: Group.ID) -> UIViewController?
    func prepareContactDetailViewController(for personID: Person.ID) throws -> UIViewController?
}

/// Holds the depencencies of the ViewControllers and loads them into view controllers.
public class MyPeopleNavigationCoordinator: AppNavigationCoordinator {
    
    var contactStore: HighLevelConstactStore
    var stateController: StateController
    
    public init() {
        contactStore = ContactStore()
        stateController = GroupStateController(contactStore: contactStore)
    }
    
    public func prepareMyPeopleViewController() -> UIViewController {
        let controller = GroupsViewController(navigationCoordinator: self, stateController: stateController)
        return controller
    }
    
    /// Wraps a NewGroupViewController in a nav controller to present modally.
    public func prepareNewGroupViewController(withInitialMembers initialMembers: [Person.ID]) -> UIViewController {
        let controller = NewGroupViewController(navigationCoordinator: self, stateController: stateController, initialMemberIDs: initialMembers)
        let navController = UINavigationController(rootViewController: controller)
        return navController
    }
    
    public func prepareGroupDetailViewController(for groupID: Group.ID) -> UIViewController? {
        let controller = GroupDetailViewController(navigationCoordinator: self, stateController: stateController, groupID: groupID)
        return controller
    }
    
    /// Throws an error if authorization is denied or rethrows any error that is encountered while fetching the contact.
    public func prepareContactDetailViewController(for personID: Person.ID) throws -> UIViewController? {
        
        guard contactStore.authorizationStatus == .authorized else {
            throw CNError(.authorizationDenied)
        }
        
        do {
            guard let person = try contactStore.fetchPerson(identifiedBy: personID, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()]) else {
                return nil
            }
            let controller = CNContactViewController(for: person.cnContact)
            controller.allowsEditing = false
            return controller
            
        } catch {
            throw error
        }
    }
}
