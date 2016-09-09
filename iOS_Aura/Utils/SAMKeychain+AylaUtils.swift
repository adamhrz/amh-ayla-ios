//
//  SAMKeychain+AylaUtils.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 9/2/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import SAMKeychain
extension SAMKeychain {
    public static func setObject(object:NSCoding?, forService serviceName: String, account: String) throws {
        let query = SAMKeychainQuery();
        query.service = serviceName;
        query.account = account;
        if let object = object {
            query.passwordData = NSKeyedArchiver.archivedDataWithRootObject(object);
            try query.save()
        } else {
            try query.deleteItem()
        }
    }
    
    public static func objectForService(serviceName: String, account:String) throws -> AnyObject? {
        let query = SAMKeychainQuery()
        query.service = serviceName
        query.account = account
        try query.fetch()
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(query.passwordData);
    }
}