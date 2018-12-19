//
//  GroupHeaderView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

public class GroupCell: UITableViewCell {
    
    public var title: String? = "" {
        didSet {
            label.text = title
        }
    }
    
    public var color: UIColor = .black {
        didSet {
            label.textColor = color
            countLabel.textColor = color
            bottomLine.backgroundColor = color
            peopleIconView.tintColor = color
        }
    }
    
    public var memberCount: Int = 0 {
        didSet {
            countLabel.text = "\(memberCount)"
        }
    }
    
    private let label: UILabel
    private let bottomLine: UIView
    private let countLabel: UILabel
    private let peopleIconView: UIImageView
    
    private static let topConstant: CGFloat = 16
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        label = UILabel()
        bottomLine = UIView(frame: .zero)
        peopleIconView = UIImageView(image: AssetCatalog.image(.people))
        countLabel = UILabel()
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 22)
        countLabel.font = UIFont.boldSystemFont(ofSize: 22)
        backgroundColor = .white
        
        peopleIconView.contentMode = .scaleAspectFit
        
        contentView.addSubview(label)
        contentView.addSubview(bottomLine)
        contentView.addSubview(peopleIconView)
        contentView.addSubview(countLabel)
        
        label.usesAutoLayout()
        bottomLine.usesAutoLayout()
        peopleIconView.usesAutoLayout()
        countLabel.usesAutoLayout()
        
        label.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.safeAreaLayoutGuide.leadingAnchor, multiplier: 1.0).isActive = true
        label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GroupCell.topConstant).isActive = true
        
        bottomLine.topAnchor.constraint(equalToSystemSpacingBelow: label.lastBaselineAnchor, multiplier: 0.5).isActive = true
        bottomLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0).isActive = true
        bottomLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        bottomLine.heightAnchor.constraint(equalToConstant: 2).isActive = true
        bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        peopleIconView.topAnchor.constraint(equalTo: countLabel.topAnchor).isActive = true
        peopleIconView.bottomAnchor.constraint(equalTo: countLabel.bottomAnchor).isActive = true
        peopleIconView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor).isActive = true
        peopleIconView.setContentCompressionResistancePriority(UILayoutPriority(250), for: .vertical)
        countLabel.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        
        countLabel.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: label.trailingAnchor, multiplier: 1.0).isActive = true
        peopleIconView.leadingAnchor.constraint(equalTo: countLabel.trailingAnchor, constant: 4).isActive = true
        countLabel.lastBaselineAnchor.constraint(equalTo: label.lastBaselineAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder: ) not implemented by GroupCell.")
    }
}
