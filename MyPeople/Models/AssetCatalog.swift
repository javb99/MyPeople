//
//  AssetCatalog.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/28/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

/// A namespace for all the images and colors in the asset catalog.
/// This is a class and not a struct to allow use of the Bundle(for:) initializer.
public class AssetCatalog {
    
    private init() {}
    public static var bundle = Bundle(for: AssetCatalog.self)
    
    public static func image(_ identifier: Image, for traitCollection: UITraitCollection? = nil) -> UIImage {
        return UIImage(named: identifier.rawValue, in: AssetCatalog.bundle, compatibleWith: traitCollection)!
    }
    
    public enum Image: String {
        case templateProfilePicture = "templateProfileImage"
        case messageBubble = "messageButton"
        case emailEnvelope = "emailButton"
        case addButton = "addButton"
    }
    
    public static func color(_ identifier: Color, for traitCollection: UITraitCollection? = nil) -> UIColor {
        return UIColor(named: identifier.rawValue, in: AssetCatalog.bundle, compatibleWith: traitCollection)!
    }
    
    public enum Color: String, Codable {
        case amaranth
        case aqua
        case funGreen
        case purplePizzazz
        case ripeLemon
        case royalPurple
        case scienceBlue
        //public static let groupColors: [Color] = [amaranth, aqua, funGreen, purplePizzazz, ripeLemon, royalPurple, scienceBlue]
        
        case blue
        case green
        case orange
        case pink
        case purple
        case red
        case teal
        case yellow
        //public static let groupColors: [Color] = [blue, green, orange, pink, purple, red, teal, yellow]
        
        case carnation
        case darkLimeGreen
        case lightGrassGreen
        case liliac
        case peach
        case seafoamBlue
        case skyBlue
        case slate
        case sunflowerYellow
        public static let groupColors: [Color] = [carnation, darkLimeGreen, liliac, peach, seafoamBlue, skyBlue, sunflowerYellow]
    }
}
