//
//  Group.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import Contacts

public struct Group: Equatable {
    
    public var name: String
    public var color: UIColor
    public var memberIDs: [String]
    /// The identifier of the CNGroup that this group is based on.
    public var identifier: String?
    
    public init(name: String, color: UIColor, people: [Person] = []) {
        self.name = name
        self.color = color
        self.memberIDs = people.map { $0.identifier! }
    }
    
    public init(_ group: CNGroup, color: UIColor, people: [Person] = []) {
        self.init(name: group.name, color: color, people: people)
        identifier = group.identifier
    }
    
    var containedContactsPredicate: NSPredicate? {
        guard let identifier = identifier else { return nil }
        return CNContact.predicateForContactsInGroup(withIdentifier: identifier)
    }
}

public extension Group {
    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.name == rhs.name
    }
}
