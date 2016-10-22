//
//  NSError+AylaErrorUtils.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK
import AFNetworking


extension NSError {
    private var responseError : String? {
        if let responseDict = self.userInfo[AylaHTTPErrorResponseJsonKey] as? [String: AnyObject] {
            if let response = responseDict["error"] as? String{
                return response.capitalizedString
            } else if let response = responseDict["errors"]{
                return response.capitalizedString
            } else if let responses = responseDict["errors"] as? [String] {
                var returnString : String? = nil
                for errorString in responses {
                    returnString = (returnString != nil ? returnString! + ", " + errorString : errorString)
                }
                return returnString?.capitalizedString
            }
        } else if let originalError = self.userInfo[AylaHTTPErrorOrignialErrorKey] as? NSError {
            return originalError.localizedDescription
        }
        return nil
    }
    
    /* If the error originated with the Ayla Cloud Service, this property will expose the HTTP status returned by the service, if found.
     * Returns nil if no AylaHTTPOriginalErrorKey is present.
     */
    var httpResponseStatus : String? {
        if let originalError = self.userInfo[AylaHTTPErrorOrignialErrorKey] as? NSError {
            if let response = originalError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? NSHTTPURLResponse {
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
        if let originalError = self.userInfo[AylaHTTPErrorOrignialErrorKey] as? NSError {
            if let response = originalError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? NSHTTPURLResponse {
                if let returnText = response.allHeaderFields["Text" as NSObject] as? String {
                    return returnText.capitalizedString
                }
            }
        }
        if let responseError = self.responseError {
            return responseError
        } else {
            print(self.userInfo)
            return "Unknown Error"
        }
    }
    
    func displayAsAlertController() {
        let message = String(format:"%@", self.aylaServiceDescription)
        (UIApplication.sharedApplication().delegate as! AppDelegate).presentAlertController("Error", message:message , withOkayButton: true, withCancelButton: false, okayHandler: nil, cancelHandler: nil)
    }
}
