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
            bottomLine.backgroundColor = color
        }
    }
    
    private let label: UILabel
    private let bottomLine: UIView
    
    private static let topConstant: CGFloat = 16
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        label = UILabel()
        bottomLine = UIView(frame: .zero)
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 22)
        backgroundColor = .white
        
        contentView.addSubview(label)
        contentView.addSubview(bottomLine)
        
        label.usesAutoLayout()
        bottomLine.usesAutoLayout()
        
        label.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.safeAreaLayoutGuide.leadingAnchor, multiplier: 1.0).isActive = true
        label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GroupCell.topConstant).isActive = true
        
        bottomLine.topAnchor.constraint(equalToSystemSpacingBelow: label.lastBaselineAnchor, multiplier: 0.5).isActive = true
        bottomLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0).isActive = true
        bottomLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        bottomLine.heightAnchor.constraint(equalToConstant: 2).isActive = true
        bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder: ) not implemented by GroupCell.")
    }
}
