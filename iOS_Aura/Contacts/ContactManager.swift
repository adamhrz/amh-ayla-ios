//
//  ContactManager.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

class ContactManager {
    static let sharedInstance = ContactManager()
    
    private(set) var contacts: [AylaContact]?

    private var sessionManager: AylaSessionManager?
    
    private init() {

    }
    
    func reload() {
        sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
        contacts = nil
        fetchContacts()
    }
    
    func contactWithID(contactID: NSNumber) -> AylaContact? {
        if let index = contacts?.indexOf({$0.id == contactID}) {
            return contacts![index]
        }
        
        return nil
    }

    private func fetchContacts() {
        sessionManager?.fetchContacts({ (contacts: [AylaContact]) in
            self.contacts = contacts
            }, failure: { (error) in
                print("- WARNING - Failed to fetch contacts! (\(error))")
        })
    }
}
