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
            bottomLine.backgroundColor = color.cgColor
            topLine.backgroundColor = color.cgColor
            backgroundColor = color.withAlphaComponent(0.1)
            layer.borderColor = color.cgColor
        }
    }
    
    private let bottomLine: CALayer
    private let topLine: CALayer
    
    public override init(frame: CGRect) {
        topLine = CALayer()
        bottomLine = CALayer()
        
        super.init(frame: frame)
        layer.addSublayer(topLine)
        layer.addSublayer(bottomLine)
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
