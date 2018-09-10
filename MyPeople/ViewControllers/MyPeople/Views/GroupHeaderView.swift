//
//  GroupHeaderView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

public class GroupHeaderView: UICollectionReusableView {
    
    public var label: UILabel
    
    private static let topConstant: CGFloat = 8
    private static let bottomConstant: CGFloat = 4
    
    public var color: UIColor = .black {
        didSet {
            label.textColor = color
        }
    }
    
    public override init(frame: CGRect) {
        label = UILabel()
        super.init(frame: frame)
        
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 22)
        
        addSubview(label)
        self.usesAutoLayout()
        label.usesAutoLayout()
        
        label.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1.0).isActive = true
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: GroupHeaderView.topConstant).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -GroupHeaderView.bottomConstant).isActive = true
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
        attributes.bounds.size.width = 300
        return attributes
    }
}
