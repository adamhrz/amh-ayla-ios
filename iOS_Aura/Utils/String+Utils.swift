//
//  String+Utils.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 4/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//
import Foundation
import UIKit

extension String {
    // These two convenience methods take an input that may be a number, a String or nil.
    
    // This method returns the String from the parameter customValueIfNil if the input is nil
    static func stringFromStringNumberOrNil(input: AnyObject?, customValueIfNil: String!) -> String{
        var checkedString = String()
        if input != nil && input!.isKindOfClass(NSNumber){
            checkedString = String(input!)
        }
        else {
            checkedString = (input as! String?) ?? customValueIfNil
        }
        return checkedString
    }
    
    // This method always returns the string "(null)" if the input is nil
    static func stringFromStringNumberOrNil(input: AnyObject?) -> String{
        var checkedString = String()
        if input != nil && input!.isKindOfClass(NSNumber){
            checkedString = String(input!)
        }
        else {
            checkedString = (input as! String?) ?? "(null)"
        }
        return checkedString
    }
    
    //  This method is used to generate a random alphanumeric sequence of specified length
    static func generateRandomAlphanumericToken(length:Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var token = ""
        
        for _ in (0..<length) {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let newCharacter = allowedChars[allowedChars.startIndex.advancedBy(randomNum)]
            token += String(newCharacter)
        }
        return token
    }
    
    
    // A boolean for whether a provided string appears to be a valid email address
    var isEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(self)
    }
    
 }