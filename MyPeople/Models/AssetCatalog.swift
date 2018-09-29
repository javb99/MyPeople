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
    public static let templateProfilePicture: UIImage = UIImage(named: "templateProfileImage", in: Bundle(for: AssetCatalog.self), compatibleWith: nil)!
    public static let messageBubble: UIImage = UIImage(named: "messageButton", in: Bundle(for: AssetCatalog.self), compatibleWith: nil)!
    public static let emailEnvelope: UIImage = UIImage(named: "emailButton", in: Bundle(for: AssetCatalog.self), compatibleWith: nil)!
}
