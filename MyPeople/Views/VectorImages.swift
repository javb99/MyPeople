//
//  VectorImages.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 1/26/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import UIKit

/// Describes something that can generate a bezier path based on some parameters. Designed with the intent of generating images from it to use as icons.
public protocol VectorImage {
    /// The stroke color to use with the bezier.
    var stroke: UIColor? { get set }
    /// The fill color to use with the bezier.
    var fill: UIColor? { get set }
    /// The bounding box to use when generating the bezier.
    var size: CGSize { get set }
    
    /// Generates the bezier path that is used to generate the image.
    var bezier: UIBezierPath { get }
}

extension VectorImage {
    /// Generate the image for this vector.
    public var image: UIImage {
        return generateImage(from: bezier, frame: CGRect(origin: .zero, size: size), stroke: stroke, fill: fill)
    }
}

fileprivate func generateImage(from bezier: UIBezierPath, frame: CGRect, stroke: UIColor? = nil, fill: UIColor? = nil) -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: frame)
    let image = renderer.image { (imageContext) in
        if let stroke = stroke {
            stroke.setStroke()
            bezier.stroke()
        }
        if let fill = fill {
            fill.setFill()
            bezier.fill()
        }
    }
    return image
}

public struct CheckmarkVector: VectorImage {
    
    public var size: CGSize
    public var stroke: UIColor?
    public var fill: UIColor?
    
    init(size: CGSize, stroke: UIColor? = nil, fill: UIColor? = nil) {
        self.size = size
        self.stroke = stroke
        self.fill = fill
    }
    
    public var bezier: UIBezierPath {
        let scaleFactor: CGFloat = floor(size.width/50)
        let checkPath = UIBezierPath()
        checkPath.move(to: CGPoint(x: 10*scaleFactor, y: 30*scaleFactor))
        checkPath.addLine(to: CGPoint(x: 22*scaleFactor, y: 40*scaleFactor))
        checkPath.addLine(to: CGPoint(x: 40*scaleFactor, y: 10*scaleFactor))
        checkPath.lineWidth = 8*scaleFactor
        checkPath.lineCapStyle = .round
        checkPath.lineJoinStyle = .round
        return checkPath
    }
}
