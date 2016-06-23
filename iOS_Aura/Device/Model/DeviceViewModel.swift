//
//  DeviceViewModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

class DeviceViewModel:NSObject, AylaDeviceListener {
    
    /// Device panel, refer to DevicePanelView for details
    weak var devicePanel: DevicePanelView?
    
    var sharesModel: DeviceSharesModel?

    /// Property list model view
    let propertyListViewModel :PropertyListViewModel?
    
    /// Device representd by this view model
    let device: AylaDevice
    
    required init(device:AylaDevice, panel:DevicePanelView?, propertyListTableView: UITableView?, sharesModel:DeviceSharesModel?) {
        self.devicePanel = panel
        self.device = device
        self.sharesModel = sharesModel
        
        if let tv = propertyListTableView {
            // If a table view has been passed in, create a property list view model and assign the input tableview to it.
            self.propertyListViewModel = PropertyListViewModel(device: device, tableView: tv)
        } else {
            self.propertyListViewModel = nil
        }
        
        super.init()
        
        // Add self as device listener
        device.addListener(self)
        self.update()
    }
    
    func shareDevice(presentingViewController:UIViewController, withShare share:AylaShare, successHandler: ((share: AylaShare) -> Void)?, failureHandler: ((error: NSError) -> Void)?){
        
        if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName){
            sessionManager.createShare(share, emailTemplate: nil, success: { (share: AylaShare) in
            NSNotificationCenter.defaultCenter().postNotificationName(AuraNotifications.SharesChanged, object:self)
                let successAlert = UIAlertController(title: "Success", message: "Device successfully shared.", preferredStyle: .Alert)
                let okayAction = UIAlertAction(title: "Okay", style: .Cancel, handler: {(action) -> Void in
                    if let successHandler = successHandler{
                        successHandler(share:share)
                    }
                })
                successAlert.addAction(okayAction)
                presentingViewController.presentViewController(successAlert, animated: true, completion: nil)
                
                }, failure: { (error: NSError) in
                    let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .Alert)
                    let gotIt = UIAlertAction(title: "Got it", style: .Cancel, handler: { (action) -> Void in
                        if let failureHandler = failureHandler{
                            failureHandler(error: error)
                        }
                    })
                    alert.addAction(gotIt)
                    presentingViewController.presentViewController(alert, animated: true, completion: nil)
            })
        }

    }
    
    func shareDevice(presentingViewController:UIViewController, successHandler: ((share: AylaShare) -> Void)?, failureHandler: ((error: NSError) -> Void)?){
        let shareStoryboard: UIStoryboard = UIStoryboard(name: "CreateShare", bundle: nil)
        let shareNavVC = shareStoryboard.instantiateInitialViewController() as! UINavigationController
        let createShareController = shareNavVC.viewControllers.first! as! CreateDeviceShareViewController
        createShareController.deviceViewModel = self
        presentingViewController.navigationController?.presentViewController(shareNavVC, animated: true, completion:nil)
        
        
    }
    
    func unregisterDeviceWithConfirmation(presentingViewController:UIViewController, successHandler: (() -> Void)?, failureHandler: ((error: NSError) -> Void)?) {
        let name = device.productName ?? "unnamed device"
        let dsn = device.dsn ?? "unknown"
        
        func unregisterDeviceWithError(){
            self.device.unregisterWithSuccess({
                    let alert = UIAlertController(title: "Device Unregistered.", message: nil, preferredStyle: .Alert)
                    let gotIt = UIAlertAction(title: "Got it", style: .Cancel, handler: {(action) -> Void in
                        if let successHandler = successHandler{successHandler()}
                    })
                    alert.addAction(gotIt)
                    presentingViewController.presentViewController(alert, animated: true, completion: nil)
                }, failure: { (error) in
                    let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .Alert)
                    let gotIt = UIAlertAction(title: "Got it", style: .Cancel, handler: {(action) -> Void in
                        if let failureHandler = failureHandler{failureHandler(error: error)}
                    })
                    alert.addAction(gotIt)
                    presentingViewController.presentViewController(alert, animated: true, completion: nil)
            })
        }
        
        if device.grant != nil { // Device is shared to the user
            let alert = UIAlertController(title:"Cannot Unregister this device", message: "This device is shared to you, so you are not able to unregister it, but you may unshare it.", preferredStyle: .Alert)
            let unshareAction = UIAlertAction(title:"Delete Share", style: .Destructive) { (action) in
                if let share =  self.sharesModel?.receivedShareForDevice(self.device) {
                    let shareViewModel = ShareViewModel(share: share)
                    shareViewModel.deleteShareWithoutConfirmation(presentingViewController, successHandler: {
                        unregisterDeviceWithError()
                        }, failureHandler: { (error) in
                            let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .Alert)
                            let gotIt = UIAlertAction(title: "Got it", style: .Cancel, handler: {(action) -> Void in
                                if let failureHandler = failureHandler{
                                    failureHandler(error: error)
                                }
                            })
                            alert.addAction(gotIt)
                            presentingViewController.presentViewController(alert, animated: true, completion: nil)
                    })
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in }
            alert.addAction(cancelAction)
            alert.addAction(unshareAction)
            presentingViewController.presentViewController(alert, animated: true, completion:nil)
        } else { // Device owned by user
            let alert = UIAlertController(title: "Are you sure you want to unregister \(name) (DSN: \(dsn))?", message: nil, preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "Unregister", style: .Destructive) { (action) in
                // Check if device is shared to anyone before unregistering
                if let shares =  self.sharesModel?.ownedSharesForDevice(self.device) {
                    // Device is shared
                    if shares.count > 0 {
                        let alert = UIAlertController(title:"Device is shared to \(shares.count) other user" + (shares.count > 1 ? "s." : "." ), message: "You must unshare it from all users to which you have shared it first.", preferredStyle: .Alert)
                        let unshareAction = UIAlertAction(title:(shares.count < 2 ? "Delete Share" : "Delete Shares"), style: .Destructive) { (action) in
                            // Delete all extant owned shares
                            var sharesCount = shares.count
                            for share in (shares as [AylaShare]!) {
                                let shareViewModel = ShareViewModel(share: share)
                                shareViewModel.deleteShareWithoutConfirmation(presentingViewController, successHandler: {
                                    sharesCount = sharesCount - 1
                                    if sharesCount == 0 {
                                        //  Unregister device when done deleting shares.
                                        let alert = UIAlertController(title: "Shares Deleted.", message: "Unregister Device Now?", preferredStyle: .Alert)
                                        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {(action) -> Void in })
                                        let continueAction = UIAlertAction(title: "Continue", style: .Destructive, handler: {(action) -> Void in
                                            unregisterDeviceWithError()
                                        })
                                        alert.addAction(cancelAction)
                                        alert.addAction(continueAction)
                                        presentingViewController.presentViewController(alert, animated: true, completion: nil)
                                    }
                                    }, failureHandler: { (error) in
                                        let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .Alert)
                                        let gotIt = UIAlertAction(title: "Got it", style: .Cancel, handler: {(action) -> Void in
                                            if let failureHandler = failureHandler{failureHandler(error: error)}
                                        })
                                        alert.addAction(gotIt)
                                        presentingViewController.presentViewController(alert, animated: true, completion: nil)
                                })
                            }
                        }
                        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in }
                        alert.addAction(cancelAction)
                        alert.addAction(unshareAction)

                        presentingViewController.presentViewController(alert, animated: true, completion:nil)
                    }
                    // Device not shared.
                    else {
                        unregisterDeviceWithError()
                    }
                // Shares comes back nil, not empty.  This shouldn't happen, but try to unregister anyway.
                } else {
                    unregisterDeviceWithError()
                }
            }
            alert.addAction(cancelAction)
            alert.addAction(okAction)
            presentingViewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func renameDevice(presentingViewController:UIViewController, successHandler: (() -> Void)?, failureHandler: ((error: NSError) -> Void)?){
        var nameTextField = UITextField()
        let alert = UIAlertController(title: "Rename " + (device.productName)!, message: "Enter the new name", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "New name"
            textField.tintColor = UIColor(red: 93.0/255.0, green: 203/255.0, blue: 152/255.0, alpha: 1.0)
            nameTextField = textField
        }
        let okAction = UIAlertAction (title: "Confirm", style: UIAlertActionStyle.Default) { (action) -> Void in
            let newName = nameTextField.text
            if newName == nil || newName!.characters.count < 1 {
                
                UIAlertController.alert("Error", message: "No name was provided", buttonTitle: "OK",fromController: presentingViewController)
                return;
            }
            self.device.updateProductNameTo(newName!, success: { () -> Void in
                let alert = UIAlertController(title: "Device renamed", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:{(action) -> Void in
                    if let successHandler = successHandler{
                        successHandler()
                    }
                })
                alert.addAction(okAction)
                presentingViewController.presentViewController(alert, animated: true, completion: nil)

                }, failure: { (error) -> Void in
                    let errorAlert = UIAlertController(title: "Device renamed", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                    let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:{(action) -> Void in
                        if let failureHandler = failureHandler{
                            failureHandler(error: error)
                        }
                    })
                    alert.addAction(okAction)
                    presentingViewController.presentViewController(errorAlert, animated: true, completion: nil)
            })
        }
        
        let cancelAction = UIAlertAction (title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        presentingViewController.presentViewController(alert, animated: true, completion: nil)
    }

    /**
     Use this method to update UI which are managed by this view model.
     */
    func update() {
        if self.devicePanel != nil {
            devicePanel?.configure(device, sharesModel:sharesModel)
        }
        // We don't update property list here since PropertyListViewModel will take care of it.
    }
    
    // MARK - device manager listener
    func device(device: AylaDevice, didFail error: NSError) {
        print("- WARNING - an error happened on device \(error)")
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        self.update()
    }
    
    func device(device: AylaDevice, didUpdateLanState isActive: Bool) {
        self.update()
    }
}