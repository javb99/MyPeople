//
//  GroupDetailHeaderView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/21/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

public protocol GroupDetailHeaderViewDelegate: class {
    func actionButtonPressed(action: GroupAction)
    func addMembersButtonPressed()
}

public class GroupDetailHeaderView: UICollectionReusableView {
    
    var model: Model {
        didSet {
            // Check that the color actually changed before updating. This saves image rendering time for the bordered button BGs.
            if model.color != oldValue.color {
                backgroundColor = model.color
                addMembersButton.styleAsDoubleBordered(with: model.color, radius: 8)
                gradientView.colors = [model.color.brighter(by: 0.25)!, model.color]
                actionButtonsView.buttonTint = model.color
            }
            
            groupNameLabel.text = model.name
        }
    }
    
    public weak var delegate: GroupDetailHeaderViewDelegate! {
        didSet {
            actionButtonsView.actionPressedCallback = delegate.actionButtonPressed
        }
    }
    
    private var gradientView: AxialGradientView
    private var groupNameLabel: UILabel
    private var addMembersButton: UIButton
    private var actionButtonsView: ActionButtonsView!
    private static let titleToActionsSpacing: CGFloat = 8
    private static let actionsToBottomSpacing: CGFloat = 8
    
    public override init(frame: CGRect) {
        gradientView = AxialGradientView()
        groupNameLabel = UILabel()
        addMembersButton = UIButton()
        actionButtonsView = ActionButtonsView(frame: .zero)
        
        model = Model()
        
        super.init(frame: frame)
        
        isUserInteractionEnabled = true
        
        // configure subviews
        
        addMembersButton.setTitle("Add", for: .normal)
        addMembersButton.addTarget(self, action: #selector(addMembersButtonPressed(_:)), for: .touchUpInside)
        addMembersButton.roundedAndInset()
        groupNameLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        groupNameLabel.textColor = .white
        
        // add subviews
        addSubview(gradientView)
        addSubview(groupNameLabel)
        addSubview(addMembersButton)
        addSubview(actionButtonsView)
        
        // set use autolayout
        self.usesAutoLayout()
        gradientView.usesAutoLayout()
        groupNameLabel.usesAutoLayout()
        addMembersButton.usesAutoLayout()
        actionButtonsView.usesAutoLayout()
        
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
        groupNameLabel.numberOfLines = 0
        groupNameLabel.lineBreakMode = .byWordWrapping
        
        addMembersButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        addMembersButton.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        
        actionButtonsView.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: GroupDetailHeaderView.titleToActionsSpacing).isActive = true
        actionButtonsView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        actionButtonsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -GroupDetailHeaderView.actionsToBottomSpacing).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let titleContentSize = groupNameLabel.sizeThatFits(size)
        let halfHeight = titleContentSize.height/2
            + GroupDetailHeaderView.titleToActionsSpacing
            + ActionButtonsView.actionButtonWidth
            + GroupDetailHeaderView.actionsToBottomSpacing
        let size = CGSize(width: titleContentSize.width,
                          height: halfHeight*2)
        
        return size
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
        color = group.meta.color
        name = group.name
    }
}
