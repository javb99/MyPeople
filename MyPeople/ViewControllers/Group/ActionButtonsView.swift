//
//  ActionButtonsView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 11/13/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import MessageUI

public enum GroupAction {
    case text
    case email
}

class ActionButtonsView: UIStackView {
    
    var actionPressedCallback: ((GroupAction)->())?
    
    private var actionButtons: [UIButton]
    
    var buttonTint: UIColor = .black {
        didSet {
            actionButtons.forEach { button in
                button.styleAsDoubleBordered(with: buttonTint, radius: ActionButtonsView.actionButtonWidth/2)
            }
        }
    }
    
    static let actionButtonWidth: CGFloat = 44
    
    override init(frame: CGRect) {
        actionButtons = []
        
        super.init(frame: frame)
        
        axis = .horizontal
        spacing = 10
        
        // Add text/iMessage button
        if MFMessageComposeViewController.canSendText() || true {
            let textButton = UIButton()
            textButton.setImage(AssetCatalog.image(.messageBubble), for: .normal)
            textButton.addTarget(self, action: #selector(sendText(_:)), for: .touchUpInside)
            actionButtons.append(textButton)
        }
        
        // Add email button
        if MFMailComposeViewController.canSendMail() || true {
            let emailButton = UIButton()
            emailButton.setImage(AssetCatalog.image(.emailEnvelope), for: .normal)
            emailButton.addTarget(self, action: #selector(sendEmail(_:)), for: .touchUpInside)
            actionButtons.append(emailButton)
        }
        
        actionButtons.forEach { button in
            addArrangedSubview(button)
            button.usesAutoLayout()
            button.widthAnchor.constraint(equalToConstant: ActionButtonsView.actionButtonWidth).isActive = true
            button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1.0).isActive = true
        }
    }
    
    required init(coder: NSCoder) {
        actionButtons = []
        super.init(coder: coder)
        actionButtons = arrangedSubviews as? [UIButton] ?? []
    }
    
    @IBAction func sendText(_ button: UIButton) {
        actionPressedCallback?(.text)
    }
    
    @IBAction func sendEmail(_ button: UIButton) {
        actionPressedCallback?(.email)
    }
}
