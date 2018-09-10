//
//  Person.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import Contacts

public class Person {
    public var name: String
    public var image: UIImage? = nil
    public var groups: [Group] = []
    /// The identifier of the CNContact that was used to create this person.
    public var identifier: String?
    
    public init(name: String) {
        self.name = name
    }
    
    public static let requiredContactKeys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor]
    
    public convenience init(_ contact: CNContact) {
        self.init(name: contact.givenName)
        if let thumnailData = contact.thumbnailImageData {
            image = UIImage(data: thumnailData)
        }
        identifier = contact.identifier
    }
    
    var thisContact: NSPredicate? {
        guard let identifier = identifier else { return nil }
        return CNContact.predicateForContacts(withIdentifiers: [identifier])
    }
    
    var isBackedByContact: Bool {
        return identifier != nil
    }
}
