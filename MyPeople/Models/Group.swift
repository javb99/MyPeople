//
//  Group.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import Contacts
import CocoaTouchAdditions

/// A logical pairing of a CNGroup with a GroupMeta object.
public struct Group {
    
    public enum _IDTag {}
    /// A special string that is an identifier for a CNGroup.
    public typealias ID = Tagged<_IDTag, String>
    
    // MARK: Stored Properties
    public let cnGroup: CNGroup
    public let meta: GroupMeta
    
    // Intended to be filled by the outside.
    public var memberIDs: [Person.ID] = []
    
    // MARK: Computed Properties
    
    /// The name of the CNGroup that this group is based on.
    public var name: String {
        return cnGroup.name
    }
    
    /// The identifier of the CNGroup that this group is based on.
    public var identifier: ID {
        return ID(rawValue: cnGroup.identifier)
    }
    
    /// A predicate to fetch all the contacts that belong to this group.
    public var containedContactsPredicate: NSPredicate {
        return CNContact.predicateForContactsInGroup(withIdentifier: identifier.rawValue)
    }
    
    public init(_ group: CNGroup, meta: GroupMeta) {
        cnGroup = group
        self.meta = meta
    }
}

extension Group: Equatable {
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.name == rhs.name
    }
}

public struct GroupMeta {
    public var colorName: AssetCatalog.Color
    public var color: UIColor {
        return AssetCatalog.color(colorName)
    }
    
    init(color: AssetCatalog.Color) {
        colorName = color
    }
}

extension GroupMeta: Codable {
    enum CodingKeys: String, CodingKey {
        case colorName
    }
    
    public init(from decoder: Decoder) throws {
        let keyedDecoder = try decoder.container(keyedBy: CodingKeys.self)
        colorName = try keyedDecoder.decode(AssetCatalog.Color.self, forKey: .colorName)
    }
    
    public func encode(into coder: Encoder) throws {
        var keyedEncoder = coder.container(keyedBy: CodingKeys.self)
        try keyedEncoder.encode(colorName, forKey: .colorName)
    }
}
