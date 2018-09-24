//
//  GroupDetailHeaderView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions
import MessageUI

public protocol GroupDetailHeaderViewDelegate: class {
    func actionButtonPressed(action: GroupAction)
    func addMembersButtonPressed()
}

public enum GroupAction {
    case text
    case email
}

public class GroupDetailHeaderView: UICollectionReusableView {
    
    var model: Model {
        didSet {
            backgroundColor = model.color
            addMembersButton.layer.borderColor = model.color.cgColor
            addMembersButton.setTitleColor(model.color, for: .normal)
            gradientView.colors = [model.color.brighter(by: 0.25)!, model.color]
            actionButtons.forEach { button in
                button.setTitleColor(model.color, for: .normal)
            }
            
            groupNameLabel.text = model.name
        }
    }
    
    public weak var delegate: GroupDetailHeaderViewDelegate!
    
    private var gradientView: AxialGradientView
    private var groupNameLabel: UILabel
    private var addMembersButton: UIButton
    private var actionButtons: [UIButton]
    
    public override init(frame: CGRect) {
        gradientView = AxialGradientView()
        groupNameLabel = UILabel()
        addMembersButton = UIButton()
        actionButtons = []
        model = Model()
        
        super.init(frame: frame)
        
        isUserInteractionEnabled = true
        
        // configure subviews
        
        addMembersButton.setTitle("Add", for: .normal)
        addMembersButton.addTarget(self, action: #selector(addMembersButtonPressed(_:)), for: .touchUpInside)
        addMembersButton.roundedAndInset()
        addMembersButton.backgroundColor = .white
        addMembersButton.layer.borderWidth = 1
        
        groupNameLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        groupNameLabel.textColor = .white
        
        // Add text/iMessage button
        if MFMessageComposeViewController.canSendText() {
            let textButton = UIButton()
            textButton.setTitle("text", for: .normal)
            textButton.addTarget(self, action: #selector(sendText(_:)), for: .touchUpInside)
            actionButtons.append(textButton)
        }
        
        // Add email button
        if MFMailComposeViewController.canSendMail() {
            let emailButton = UIButton()
            emailButton.setTitle("mail", for: .normal)
            emailButton.addTarget(self, action: #selector(sendEmail(_:)), for: .touchUpInside)
            actionButtons.append(emailButton)
        }
        
        actionButtons.forEach { button in
            button.maskToCorners(ofRadius: 22)
            button.backgroundColor = .white
        }
        
        let actionButtonsStackView = UIStackView(arrangedSubviews: actionButtons)
        actionButtonsStackView.axis = .horizontal
        actionButtonsStackView.spacing = 10
        
        // add subviews
        addSubview(gradientView)
        addSubview(groupNameLabel)
        addSubview(addMembersButton)
        addSubview(actionButtonsStackView)
        
        // set use autolayout
        self.usesAutoLayout()
        gradientView.usesAutoLayout()
        groupNameLabel.usesAutoLayout()
        addMembersButton.usesAutoLayout()
        actionButtonsStackView.usesAutoLayout()
        actionButtons.forEach { $0.usesAutoLayout() }
        
        // set constraints
        //self.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        gradientView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        gradientView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        gradientView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        gradientView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        groupNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        groupNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        groupNameLabel.trailingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: trailingAnchor, multiplier: 1.0).isActive = true
        groupNameLabel.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: leadingAnchor, multiplier: 1.0).isActive = true
        groupNameLabel.numberOfLines = 2
        
        addMembersButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        addMembersButton.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        
        actionButtons.forEach { button in
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1.0).isActive = true
        }
        
        actionButtonsStackView.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: 8).isActive = true
        actionButtonsStackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        actionButtonsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func addMembersButtonPressed(_ button: UIButton) {
        delegate.addMembersButtonPressed()
    }
    
    @IBAction func sendText(_ button: UIButton) {
        delegate.actionButtonPressed(action: .text)
    }
    
    @IBAction func sendEmail(_ button: UIButton) {
        delegate.actionButtonPressed(action: .email)
    }
}

extension GroupDetailHeaderView {
    struct Model {
        var color: UIColor
        var name: String
    }
}

extension GroupDetailHeaderView.Model {
    init() {
        color = .black
        name = "Unnamed"
    }
}

extension GroupDetailHeaderView.Model {
    init(group: Group) {
        color = group.color
        name = group.name
    }
}