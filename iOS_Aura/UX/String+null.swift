//
//  String+null.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 4/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//
import Foundation
import UIKit

extension String {
    
    static func stringOrNull(input: AnyObject?) -> String{
        var checkedString = String()
        if input != nil && !input!.isMemberOfClass(NSNumber){
            checkedString = String(input!)
        }
        else {
            checkedString = (input as! String?) ?? "(null)"
        }
        return checkedString
    }
}