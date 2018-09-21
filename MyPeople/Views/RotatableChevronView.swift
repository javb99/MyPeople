//
//  DisclosureIndicator.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/17/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

public class RotatableChevronView: UIView {

    public private(set) var viewModel: ViewModel
    
    private let chevronLayer: CAShapeLayer
    
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 6, y: 6))
        path.addLine(to: CGPoint(x: 0, y: 12))
        
        let shapeLayer = CAShapeLayer(path, fillColor: .clear)
        shapeLayer.strokeColor = viewModel.color.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.frame = CGRect(x: 0, y: 0, width: 6, height: 12)
        shapeLayer.anchorPoint = .unitCenter
        
        chevronLayer = shapeLayer
        
        // These adjustments allow the corners to not be cut off.
        let frame = CGRect(x: 0, y: 0, width: shapeLayer.frame.width+2, height: shapeLayer.frame.height+2)
        shapeLayer.position = frame.center
        
        super.init(frame: frame)
        backgroundColor = .white
        layer.addSublayer(shapeLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public func set(viewModel newViewModel: ViewModel, animated: Bool) {
        
        if newViewModel.color != viewModel.color {
            let changeColor = { self.chevronLayer.strokeColor = newViewModel.color.cgColor }
            if animated {
                UIView.animate(withDuration: 0.3, animations: changeColor)
            } else {
                changeColor()
            }
        }
        
        if newViewModel.direction != viewModel.direction {
            let transform = CGAffineTransform(rotationAngle: newViewModel.direction)
            if animated {
                UIView.animate(withDuration: 0.3) {
                    // Doing it this way makes the animation go back and forth rather than completing a circle.
                    let animation = CABasicAnimation(keyPath: "transform")
                    animation.toValue = transform
                    self.layer.add(animation, forKey: "transform")
                    
                    self.layer.setAffineTransform(transform)
                }
            } else {
                layer.setAffineTransform(transform)
            }
        }
        
        viewModel = newViewModel
    }
}

public extension RotatableChevronView {
    public struct ViewModel {
        /// Radians counter clockwise with 0 pointing directly left.
        var direction: CGFloat
        var color: UIColor
    }
}

//
// MARK: - View Model Layer -
//

extension RotatableChevronView.ViewModel {
    init(collapsedState: CollapsibleState, color: UIColor) {
        switch collapsedState {
        case .open, .uncollapsible:
            direction = -CGFloat.pi/2 // Pointing down
        case .collapsed:
            direction = CGFloat.pi/2 // Pointing up
        }
        self.color = color
    }
}
