//
//  PersonCell.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

public class PersonCell: UICollectionViewCell {
    
    public let profileCircle: PersonProfilePictureView
    public let nameLabel: UILabel
    
    public override init(frame: CGRect) {
        profileCircle = PersonProfilePictureView(frame: .init(squareOfLength: 60))
        nameLabel = UILabel()
        super.init(frame: frame)
        
        contentView.addSubview(profileCircle)
        contentView.addSubview(nameLabel)
        
        profileCircle.usesAutoLayout()
        nameLabel.usesAutoLayout()
        
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        
        NSLayoutConstraint.activate([
            profileCircle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileCircle.topAnchor.constraint(equalTo: contentView.topAnchor),
            profileCircle.widthAnchor.constraint(equalToConstant: 60),
            profileCircle.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: profileCircle.bottomAnchor, constant: 2),
            
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
