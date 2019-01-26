//
//  PersonCell.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

public class PersonCell: UICollectionViewCell {
    
    private let profileCircle: PersonPictureView
    private let nameLabel: UILabel
    
    public var viewModel: ViewModel {
        didSet {
            nameLabel.text = viewModel.name
            profileCircle.bgColors = viewModel.colors
            profileCircle.image = viewModel.profilePicture
        }
    }
    public override var isSelected: Bool {
        didSet {
            if isSelected {
                profileCircle.bgColors = [.blue]
            } else {
                profileCircle.bgColors = viewModel.colors
            }
        }
    }
    
    private static let circleVerticalSpacingToName: CGFloat = 2
    private static let profileCircleWidth: CGFloat = 60
    
    public override init(frame: CGRect) {
        profileCircle = PersonPictureView(frame: .init(squareOfLength: 60))
        nameLabel = UILabel()
        viewModel = ViewModel()
        super.init(frame: frame)
        
        contentView.addSubview(profileCircle)
        contentView.addSubview(nameLabel)
        
        profileCircle.usesAutoLayout()
        nameLabel.usesAutoLayout()
        
        nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        
        NSLayoutConstraint.activate([
            profileCircle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileCircle.topAnchor.constraint(equalTo: contentView.topAnchor),
            profileCircle.widthAnchor.constraint(equalToConstant: PersonCell.profileCircleWidth),
            profileCircle.heightAnchor.constraint(equalToConstant: PersonCell.profileCircleWidth),
            
            nameLabel.topAnchor.constraint(equalTo: profileCircle.bottomAnchor, constant: PersonCell.circleVerticalSpacingToName),
            
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: max(nameLabel.intrinsicContentSize.width, PersonCell.profileCircleWidth), height: PersonCell.profileCircleWidth + PersonCell.circleVerticalSpacingToName + nameLabel.intrinsicContentSize.height)
    }
}

extension PersonCell {
    public struct ViewModel {
        public var name: String
        public var profilePicture: UIImage?
        public var colors: [UIColor]
    }
}

extension PersonCell.ViewModel {
    init() {
        colors = []
        name = "Unnamed"
        profilePicture = nil
    }
}

//
// MARK: - View Model Layer -
//
extension PersonCell.ViewModel {
    
    init(person: Person, colors: [UIColor]) {
        self.colors = colors
        name = person.name
        profilePicture = person.image
    }
}
