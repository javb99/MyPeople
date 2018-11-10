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

public struct Group: Equatable {
    
    public enum _IDTag {}
    public typealias ID = Tagged<_IDTag, String>
    
    public var name: String
    public var colorName: AssetCatalog.Color
    public var color: UIColor {
        return AssetCatalog.color(colorName)
    }
    public var memberIDs: [Person.ID]
    /// The identifier of the CNGroup that this group is based on.
    public var identifier: ID?
    
    public init(name: String, color: AssetCatalog.Color, people: [Person] = []) {
        self.name = name
        self.colorName = color
        self.memberIDs = people.map { $0.identifier! }
    }
    
    public init(_ group: CNGroup, color: AssetCatalog.Color, people: [Person] = []) {
        self.init(name: group.name, color: color, people: people)
        identifier = ID(rawValue: group.identifier)
    }
    
    var containedContactsPredicate: NSPredicate? {
        guard let identifier = identifier else { return nil }
        return CNContact.predicateForContactsInGroup(withIdentifier: identifier.rawValue)
    }
}

extension Group: Codable {
    enum CodingKeys: String, CodingKey {
        case identifier
        case colorName
        case name
    }
    
    public init(from decoder: Decoder) throws {
        let keyedDecoder = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try keyedDecoder.decode(ID?.self, forKey: .identifier)
        colorName = try keyedDecoder.decode(AssetCatalog.Color.self, forKey: .colorName)
        name = try keyedDecoder.decode(String.self, forKey: .name)
        memberIDs = []
    }
    
    public func encode(into coder: Encoder) throws {
        var keyedEncoder = coder.container(keyedBy: CodingKeys.self)
        try keyedEncoder.encode(identifier, forKey: .identifier)
        try keyedEncoder.encode(colorName, forKey: .colorName)
        try keyedEncoder.encode(name, forKey: .name)
    }
}

public extension Group {
    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.name == rhs.name
    }
}
