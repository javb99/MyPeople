//
//  ActionButtonsView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 11/13/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

private let actionButtonWidth: CGFloat = 44

struct ActionButtonProperties {
    /// A template image for the button.
    var image: UIImage
    /// enables or disables the button.
    var isEnabled: Bool
    /// Applies red tint color for true and the group tint for false.
    var isDestructive: Bool
}

protocol ActionButtonsDataSource: class {
    func visibleButtons() -> [Action]
    func properties(for action: Action) -> ActionButtonProperties
}

/// A horizontal stack of action buttons. The properties of each button are controlled by the dataSource.
class GroupDetailToolbar: UIStackView {
    
    private var actionButtons: [IdentifiableButton<Action>]
    
    weak var dataSource: ActionButtonsDataSource?
    var buttonPressedCallback: ( (Action)->() )?
    
    var buttonTint: UIColor = .black
    
    init() {
        actionButtons = []
        super.init(frame: .zero)
        
        axis = .horizontal
        spacing = 10
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    public func reloadButtons() {
        actionButtons.forEach { $0.removeFromSuperview() }
        guard let dataSource = dataSource else {
            print("Data source is nil.")
            return }
        let actions = dataSource.visibleButtons()
        for action in actions {
            let properties = dataSource.properties(for: action)
            addButton(for: action, with: properties)
        }
    }
    
    public func button(for action: Action) -> UIButton {
        guard let index = actionButtons.firstIndex(where: { $0.identifier == action }) else {
            fatalError("No button for that id.")
        }
        return actionButtons[index]
    }
    
    public func addButton(for action: Action, with properties: ActionButtonProperties) {
        let button = IdentifiableButton<Action>(id: action)
        button.setImage(properties.image, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button.styleAsDoubleBordered(with: properties.isDestructive ? .red : buttonTint, radius: actionButtonWidth/2)
        button.isEnabled = properties.isEnabled
        actionButtons.append(button)
        
        addArrangedSubview(button)
        button.usesAutoLayout()
        button.widthAnchor.constraint(equalToConstant: actionButtonWidth).isActive = true
        button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1.0).isActive = true
    }
    
    @IBAction func buttonPressed(_ button: UIButton) {
        guard let idButton = button as? IdentifiableButton<Action> else {
            fatalError("Button that was pressed was not \(IdentifiableButton<Action>.self)")
        }
        buttonPressedCallback?(idButton.identifier)
    }
}
