//
//  UIView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/28/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import CocoaTouchAdditions

extension UIButton {
    
    func styleAsDoubleBordered(with color: UIColor, radius: CGFloat) {
        imageView?.tintColor = color
        
        setTitleColor(color, for: .normal)
        let normalBGImage = UIImage.resizableBorderedColor(main: .white, border: color, outerBorder: .white, borderRadius: radius, borderThickness: 3)
        setBackgroundImage(normalBGImage, for: .normal)
        
        let selectedBGImage = UIImage.resizableBorderedColor(main: UIColor.white.overlay(color.settingAlpha(to: 0.2)), border: color, outerBorder: .white, borderRadius: radius, borderThickness: 3)
        setBackgroundImage(selectedBGImage, for: .highlighted)
    }
}

extension UIEdgeInsets {
    /// Use the same value for all 4 edges.
    init(singleValue: CGFloat) {
        self.init(top: singleValue,
                     left: singleValue,
                     bottom: singleValue,
                     right: singleValue)
    }
}

extension UIImage {
    public static func resizableBorderedColor(main mainColor: UIColor, border borderColor: UIColor, outerBorder outerBorderColor: UIColor, borderRadius: CGFloat, borderThickness: CGFloat) -> UIImage {
        let width = borderRadius*2
        let imageSize = CGSize(width: width, height: width)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let bounds = CGRect(origin: .zero, size: imageSize)
        
        let outerBorderThickness = borderThickness*2/3
        let innerBorderThickness = borderThickness/3
        let image = renderer.image { (context) in
            
            // The fill color
            let outerBezier = UIBezierPath(roundedRect: bounds.inset(by: UIEdgeInsets(singleValue: outerBorderThickness/2)), cornerRadius: borderRadius-outerBorderThickness/2)
            mainColor.setFill()
            outerBezier.fill()
            
            // The outer border
            outerBorderColor.setStroke()
            outerBezier.lineWidth = outerBorderThickness
            outerBezier.stroke()
            
            // The colored border
            let innerBezier = UIBezierPath(roundedRect: bounds.inset(by: UIEdgeInsets(singleValue: outerBorderThickness + innerBorderThickness/2)), cornerRadius: borderRadius-outerBorderThickness-innerBorderThickness/2)
            borderColor.setStroke()
            innerBezier.lineWidth = innerBorderThickness
            innerBezier.stroke()
        }
        let resizableImage = image.resizableImage(withCapInsets: UIEdgeInsets(singleValue: borderRadius))
        return resizableImage
    }
}
