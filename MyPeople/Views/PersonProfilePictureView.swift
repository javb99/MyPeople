//
//  PersonProfilePictureView.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

public class PersonProfilePictureView: UIView {
    
    private var circlesParentLayer: CALayer
    private var circlesView: UIView
    private let imageView: UIImageView
    
    public static let placeholderProfileImage: UIImage = UIImage(named: "templateProfileImage", in: Bundle(for: PersonProfilePictureView.self), compatibleWith: nil)!
    
    public var bgColors: [UIColor] {
        didSet {
            reloadCirclesView()
        }
    }
    
    public var image: UIImage? {
        didSet {
            imageView.image = image ?? PersonProfilePictureView.placeholderProfileImage
        }
    }
    
    public init(frame: CGRect, bgColors: [UIColor] = [], image: UIImage? = nil) {
        self.bgColors = bgColors
        self.image = image
        circlesParentLayer = CALayer()
        circlesView = UIView()
        imageView = UIImageView(frame: frame.insetBy(dx: floor(frame.width/20), dy: floor(frame.height/20)))
        
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = image ?? PersonProfilePictureView.placeholderProfileImage
        imageView.circleBordered(by: .white, width: 2)
        
        reloadCirclesView()
        
        addSubview(circlesView)
        addSubview(imageView)
    }
    
    private func reloadCirclesView() {
        circlesParentLayer.removeFromSuperlayer()
        circlesParentLayer = createCirclesParentLayer()
        circlesView.layer.addSublayer(circlesParentLayer)
        circlesView.frame = circlesParentLayer.frame
    }
    
    private func createCirclesParentLayer() -> CALayer {
        let layer = CALayer()
        layer.anchorPoint = .unitCenter
        let radius = floor(frame.width/2)
        for (i, color) in bgColors.enumerated() {
            let arcLayer = CAShapeLayer(UIBezierPath(sliceNumber: i, of: bgColors.count, radius: radius, center: bounds.center, offsetByRadians: -CGFloat.pi/2), fillColor: color)
            arcLayer.anchorPoint = .unitLeftBottom
            layer.addSublayer(arcLayer)
        }
        return layer
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
