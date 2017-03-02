//
//  NSError+AylaErrorUtils.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK
import AFNetworking


extension Error {
    fileprivate var responseError : String? {
        if let responseDict = (self as NSError).userInfo[AylaHTTPErrorResponseJsonKey] as? [String: AnyObject] {
            print("Ayla Error")
            for (key, value) in responseDict {
                print("   \(key) : \(value)")
            }
            if let msg = responseDict["msg"] {
                var message: String = (msg as? String) ?? ""
                if let code = responseDict["error"] {
                    message = message + " (\(code))"
                }
                return message.capitalized
            } else if let response = responseDict["error"] as? String{
                return response.capitalized
            } else if let response = responseDict["errors"]{
                return response.capitalized
            } else if let responses = responseDict["errors"] as? [String] {
                var returnString : String? = nil
                for errorString in responses {
                    returnString = (returnString != nil ? returnString! + ", " + errorString : errorString)
                }
                return returnString?.capitalized
            }
        } else if let originalError = (self as NSError).userInfo[AylaHTTPErrorOrignialErrorKey] as? NSError {
            return originalError.localizedDescription
        }
        return nil
    }
    
    /* If the error originated with the Ayla Cloud Service, this property will expose the HTTP status returned by the service, if found.
     * Returns nil if no AylaHTTPOriginalErrorKey is present.
     */
    var httpResponseStatus : String? {
        if let originalError = (self as NSError).userInfo[AylaHTTPErrorOrignialErrorKey] as? NSError {
            if let response = originalError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? HTTPURLResponse {
                if let returnStatus = response.allHeaderFields["Status" as NSObject] as? String {
                    return returnStatus
                } else {
                    return originalError.localizedDescription
                }
            }
        }
        return nil
    }
    
    /* If the error originated with the Ayla Cloud Service, this property will expose the text returned by the service, if found.
     * Returns nil if no error text is present.
     */
    var aylaServiceDescription : String! {
        if let originalError = (self as NSError).userInfo[AylaHTTPErrorOrignialErrorKey] as? NSError {
            if let response = originalError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? HTTPURLResponse {
                if let returnText = response.allHeaderFields["Text" as NSObject] as? String {
                    return returnText.capitalized
                }
            }
        }
        if let responseError = self.responseError {
            return responseError
        } else {
            print((self as NSError).userInfo)
            return "Unknown Error"
        }
    }
    
    /* If the error originated with the Ayla Cloud Service, this property will return the Ayla error code.
     */
    var aylaResponseErrorCode : Int! {
        if let responseDict = (self as NSError).userInfo[AylaHTTPErrorResponseJsonKey] as? [String: AnyObject] {
            print("Ayla Error")
            for (key, value) in responseDict {
                print("   \(key) : \(value)")
            }
            if let code = responseDict["error"] as? Int {
                    return code
            }
        }
        return 0
    }
    
    func displayAsAlertController() {
        let message = String(format:"%@", self.aylaServiceDescription)
        (UIApplication.shared.delegate as! AppDelegate).presentAlertController("Error", message:message , withOkayButton: true, withCancelButton: false, okayHandler: nil, cancelHandler: nil)
    }
    
    var description :String {
        get {
            return self.localizedDescription
        }
    }
}

