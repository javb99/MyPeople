//
//  GroupDetailToolbarDataSource.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 12/28/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import MessageUI

public enum Action {
    // Default cases
    
    case text
    case email
    
    static let defaultButtons: Set<Action> = [.text, .email]
    
    // Editing cases
    
    case remove
    case newGroup
    
    static let editingButtons: Set<Action> = [.remove, .newGroup]
}

class GroupDetailToolbarDataSource: ActionButtonsDataSource {
    var isEditing: Bool = false
    var hasSelection: Bool = false
    
    func visibleButtons() -> [Action] {
        if isEditing {
            return  [.text, .email, .remove, .newGroup]
        } else {
            return [.text, .email]
        }
    }
    
    var isEmailEnabled: Bool { return MFMailComposeViewController.canSendMail() }
    var isTextEnabled: Bool { return MFMessageComposeViewController.canSendText() }
    
    func properties(for action: Action) -> ActionButtonProperties {
        let editingAndSelection = isEditing && hasSelection
        switch action {
        case .text:
            return ActionButtonProperties(image: AssetCatalog.image(.messageBubble), isEnabled: isTextEnabled && ( !isEditing || editingAndSelection ), isDestructive: false)
        case .email:
            return ActionButtonProperties(image: AssetCatalog.image(.emailEnvelope), isEnabled: isEmailEnabled && ( !isEditing || editingAndSelection ), isDestructive: false)
        case .remove:
            return ActionButtonProperties(image: AssetCatalog.image(.removeButton), isEnabled:  editingAndSelection, isDestructive: true)
        case .newGroup:
            return ActionButtonProperties(image: AssetCatalog.image(.addButton), isEnabled:  editingAndSelection, isDestructive: false)
        }
    }
}
