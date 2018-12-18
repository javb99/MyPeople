//
//  GroupDetailModalListener.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 12/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import ContactsUI
import MessageUI

/// An object to handle the callbacks for the various modal screens displayed by the GroupDetailViewController.
public class GroupDetailModalListener: NSObject {
    public var stateController: StateController
    public var group: Group
    
    public init(group: Group, stateController: StateController) {
        self.group = group
        self.stateController = stateController
    }
}

extension GroupDetailModalListener: CNContactPickerDelegate {
    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let people = contacts.map { Person.ID(rawValue: $0.identifier) }
        stateController.add(people: people, toGroup: group.identifier )
        picker.dismiss(animated: true, completion: nil)
    }
}

extension GroupDetailModalListener: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension GroupDetailModalListener: MFMessageComposeViewControllerDelegate {
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
