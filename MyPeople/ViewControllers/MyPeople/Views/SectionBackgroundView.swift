//
//  SectionBackgroundView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

public class SectionBackgroundView: UICollectionReusableView {
    
    public static let kind: String = "SectionBackgroundView"
    
    public var color: UIColor = .clear {
        didSet {
            bottomLine.backgroundColor = color
            topLine.backgroundColor = color
            backgroundColor = color.settingAlpha(to: 0.1)
        }
    }
    
    private let bottomLine: UIView
    private let topLine: UIView
    
    public override init(frame: CGRect) {
        topLine = UIView(frame: .zero)
        bottomLine = UIView(frame: .zero)
        super.init(frame: frame)
        addSubview(topLine)
        addSubview(bottomLine)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        topLine.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        bottomLine.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 1)
    }
    
    public override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.bounds.size.height = intrinsicContentSize.height
        return attributes
    }
}
