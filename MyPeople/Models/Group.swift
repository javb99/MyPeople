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
    public var color: UIColor
    public var memberIDs: [Person.ID]
    /// The identifier of the CNGroup that this group is based on.
    public var identifier: ID?
    
    public init(name: String, color: UIColor, people: [Person] = []) {
        self.name = name
        self.color = color
        self.memberIDs = people.map { $0.identifier! }
    }
    
    public init(_ group: CNGroup, color: UIColor, people: [Person] = []) {
        self.init(name: group.name, color: color, people: people)
        identifier = ID(rawValue: group.identifier)
    }
    
    var containedContactsPredicate: NSPredicate? {
        guard let identifier = identifier else { return nil }
        return CNContact.predicateForContactsInGroup(withIdentifier: identifier.rawValue)
    }
}

public extension Group {
    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.name == rhs.name
    }
}
