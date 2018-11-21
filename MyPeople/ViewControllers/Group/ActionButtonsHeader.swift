//
//  ActionButtonsHeader.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 11/18/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

public protocol ActionButtonsHeaderDelegate: class {
    func actionButtonPressed(action: GroupAction)
    func addMembersButtonPressed()
}

public class ActionButtonsHeader: UICollectionReusableView {
    
    var color: UIColor {
        didSet {
            // Check that the color actually changed before updating.
            // This saves image rendering time for the bordered button BGs.
            if color != oldValue {
                actionButtonsView.buttonTint = color
                backgroundColor = color//.withAlphaComponent(0.2)
            }
        }
    }
    
    public weak var delegate: ActionButtonsHeaderDelegate! {
        didSet {
            actionButtonsView.actionPressedCallback = delegate.actionButtonPressed
        }
    }
    
    private var actionButtonsView: ActionButtonsView!
    
    public static let bottomSpacing: CGFloat = 4
    
    public override init(frame: CGRect) {
        actionButtonsView = ActionButtonsView(frame: .zero)
        color = .black
        super.init(frame: frame)
        
        isUserInteractionEnabled = true
        
        addSubview(actionButtonsView)
        actionButtonsView.usesAutoLayout()
        actionButtonsView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        actionButtonsView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        actionButtonsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ActionButtonsHeader.bottomSpacing).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let size = CGSize(width: size.width,
                          height: ActionButtonsView.actionButtonWidth + ActionButtonsHeader.bottomSpacing)
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
