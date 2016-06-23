//
//  DeviceShareViewModel.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/5/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK


class ShareViewModel: NSObject, UITextFieldDelegate, AylaDeviceManagerListener, AylaDeviceListener {
    
    /// Share presented by this model
    var share: AylaShare
    
    /// Reference to device used in this share.
    weak var device: AylaDevice?
    
    /// Reference to current session manager.
    weak var sessionManager: AylaSessionManager?
    
    static let DeviceShareCellId: String = "DeviceShareCellId"
    
    required init(share:AylaShare) {
        self.share = share
        if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
            self.sessionManager = sessionManager
            
            var devices : [AylaDevice]
            devices = sessionManager.deviceManager.devices.values.map({ (device) -> AylaDevice in
                return device as! AylaDevice
            })
            
            for device in devices {
                if device.dsn == share.resourceId {
                    self.device = device
                }
            }
            
            super.init()
        }
        else {
            print("No Session manager present")
            super.init()
        }
    }
    
    
    
    func deleteShare(presentingViewController:UIViewController, successHandler: (() -> Void)?, failureHandler: ((error: NSError) -> Void)?) {
        if let sessionManager = sessionManager {
            let confirmation = UIAlertController(title: "Delete this Share?", message: "Are you sure you want to unshare this device?", preferredStyle: .Alert)
            let delete = UIAlertAction(title: "Delete Share", style: .Destructive, handler:{(action) -> Void in
                sessionManager.deleteShare(self.share, success: {
                    NSNotificationCenter.defaultCenter().postNotificationName(AuraNotifications.SharesChanged, object:self)
                    if let successHandler = successHandler {
                        successHandler()
                    }
                    }, failure: { (error) in
                        let alert = UIAlertController(title: "Error. Failed to Delete Share.", message: error.description, preferredStyle: .Alert)
                        let gotIt = UIAlertAction(title: "Got it", style: .Cancel, handler: nil)
                        alert.addAction(gotIt)
                        presentingViewController.presentViewController(alert, animated: true, completion: nil)
                        if let failureHandler = failureHandler {
                            failureHandler(error: error)
                        }
                })
            })
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            confirmation.addAction(delete)
            confirmation.addAction(cancel)
            presentingViewController.presentViewController(confirmation, animated: true, completion: nil)
            
        }
        else {
            print("No Session Manager found!")
        }
        
    }
    
    func deleteShareWithoutConfirmation(presentingViewController:UIViewController, successHandler: (() -> Void)?, failureHandler: ((error: NSError) -> Void)?) {
        if let sessionManager = sessionManager {
            sessionManager.deleteShare(self.share, success: {
                NSNotificationCenter.defaultCenter().postNotificationName(AuraNotifications.SharesChanged, object:self)
                if let successHandler = successHandler {
                    successHandler()
                }
                }, failure: { (error) in
                    let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .Alert)
                    let gotIt = UIAlertAction(title: "Got it", style: .Cancel, handler: nil)
                    alert.addAction(gotIt)
                    presentingViewController.presentViewController(alert, animated: true, completion: nil)
                    if let failureHandler = failureHandler {
                        failureHandler(error: error)
                    }
            })
        } else {
            print("No Session Manager found!")
        }
    }
    
    func valueFromString(str:String?) -> AnyObject? {
        
        if str == nil {
            return nil;
        }
        else if self.share.userEmail == "string" {
            return str;
        }
        else {
            if let doubleValue = Double(str!) {
                return NSNumber(double: doubleValue)
            }
        }
        
        return nil
    }
    
    
    // MARK - device manager listener
    func deviceManager(deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : NSError]) {
        print("Init complete")
    }
    
    func deviceManager(deviceManager: AylaDeviceManager, didInitFailure error: NSError) {
        print("Failed to init: \(error)")
    }
    
    func deviceManager(deviceManager: AylaDeviceManager, didObserveDeviceListChange change: AylaDeviceListChange) {
        print("Observe device list change")
        if change.addedItems.count > 0 {
            for device:AylaDevice in change.addedItems {
                device.addListener(self)
            }
        }
        else {
            // We don't remove self as listener from device manager removed devices.
        }
    }
    
    func deviceManager(deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState){
        
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        if change.isKindOfClass(AylaDeviceChange) {
            // Not a good udpate strategy
        }
    }
    
    func device(device: AylaDevice, didFail error: NSError) {
        // Device errors are not handled here.
    }
}