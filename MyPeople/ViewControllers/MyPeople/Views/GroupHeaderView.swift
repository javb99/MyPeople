//
//  GroupHeaderView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

public class GroupHeaderView: UICollectionReusableView, CollapsibleSectionHeader {
    
    public var title: String? = "" {
        didSet {
            label.text = title
        }
    }
    
    public var state: CollapsibleState = .uncollapsible {
        didSet {
            disclosureIndicator.set(viewModel: .init(collapsedState: state, color: color), animated: true)
        }
    }
    
    public var color: UIColor = .black {
        didSet {
            label.textColor = color
            bottomLine.backgroundColor = color
            disclosureIndicator.set(viewModel: .init(collapsedState: state, color: color), animated: true)
        }
    }
    
    public var titleTouchedCallback: ((UITapGestureRecognizer)->())? = nil
    public var sectionToggleTouchedCallback: ((UITapGestureRecognizer)->())? = nil
    
    private let label: UILabel
    private let disclosureIndicator: RotatableChevronView
    private let bottomLine: UIView
    
    private static let topConstant: CGFloat = 8
    private static let bottomConstant: CGFloat = 4
    
    public override init(frame: CGRect) {
        label = UILabel()
        disclosureIndicator = RotatableChevronView(viewModel: .init(collapsedState: state, color: color))
        bottomLine = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        super.init(frame: frame)
        
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 22)
        backgroundColor = .white
        
        addSubview(label)
        addSubview(disclosureIndicator)
        addSubview(bottomLine)
        
        isUserInteractionEnabled = true
        
        let touchGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touched(_:)))
        self.addGestureRecognizer(touchGestureRecognizer)
        
        self.usesAutoLayout()
        label.usesAutoLayout()
        disclosureIndicator.usesAutoLayout()
        bottomLine.usesAutoLayout()
        
        label.leadingAnchor.constraint(equalToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1.0).isActive = true
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: GroupHeaderView.topConstant).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -GroupHeaderView.bottomConstant).isActive = true
        
        disclosureIndicator.widthAnchor.constraint(equalToConstant: disclosureIndicator.frame.width).isActive = true
        disclosureIndicator.heightAnchor.constraint(equalToConstant: disclosureIndicator.frame.height).isActive = true
        self.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: disclosureIndicator.trailingAnchor, constant: 16).isActive = true
        disclosureIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
        
        bottomLine.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0).isActive = true
        bottomLine.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        bottomLine.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: label.intrinsicContentSize.width, height: GroupHeaderView.topConstant + label.intrinsicContentSize.height + GroupHeaderView.bottomConstant)
    }
    
    public override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.bounds.size.height = intrinsicContentSize.height
        return attributes
    }
    
    @IBAction func touched(_ tapGC: UITapGestureRecognizer) {
        let location = tapGC.location(in: self)
        var extendedChevronFrame = CGRect(x: 0, y: 0, width: 50, height: bounds.height)
        extendedChevronFrame.center = disclosureIndicator.frame.center
        if label.frame.contains(location) {
            titleTouchedCallback?(tapGC)
        } else if extendedChevronFrame.contains(location) {
            sectionToggleTouchedCallback?(tapGC)
        }
    }
}
