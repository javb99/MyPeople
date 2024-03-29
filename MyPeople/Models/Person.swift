//
//  Person.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import Contacts
import CocoaTouchAdditions

public enum _EmailTag {}
public typealias Email = Tagged<_EmailTag, String>

public enum _PhoneNumberTag {}
public typealias PhoneNumber = Tagged<_PhoneNumberTag, String>

public struct Person {
    public enum _IDTag {}
    public typealias ID = Tagged<_IDTag, String>
    
    public var name: String
    public var image: UIImage? = nil
    public var email: Email? = nil
    public var phoneNumber: PhoneNumber? = nil
    /// The identifier of the CNContact that was used to create this person.
    public let identifier: ID
    public let cnContact: CNContact
    /// Set from the outside.
    public var groupIDs: Set<Group.ID> = []
    
    public static let requiredContactKeys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
    
    public init(_ contact: CNContact) {
        cnContact = contact
        
        name = contact.givenName
        
        if let thumnailData = contact.thumbnailImageData {
            image = UIImage(data: thumnailData)
        }
        identifier = .init(rawValue: contact.identifier)
        
        if let emailString = contact.emailAddresses.first?.value as String? {
            email = .init(rawValue: emailString)
        } else {
            email = nil
        }
        
        if let phoneNumberString = contact.phoneNumbers.first?.value.stringValue {
            phoneNumber = .init(rawValue: phoneNumberString)
        } else {
            phoneNumber = nil
        }
    }
    
    static func predicate(for identifier: Person.ID) -> NSPredicate {
        return CNContact.predicateForContacts(withIdentifiers: [identifier.rawValue])
    }
}
