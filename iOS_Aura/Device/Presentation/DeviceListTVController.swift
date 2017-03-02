//
//  DeviceListTVController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import Ayla_LocalDevice_SDK
import ActionSheetPicker_3_0

class DeviceListTVController: UITableViewController, DeviceListViewModelDelegate {
    
    /// Id of a segue which is linked to GrillRight device page.
    let segueIdToGrillRight = "GrillRightDeviceSegue"
    
    /// Id of a segue which is linked to device page.
    let segueIdToDevice :String = "toDevicePage"
    
    /// Segue id to property view
    let segueIdToRegisterView :String = "toRegisterPage"
    
    /// Segue id to Shares List view
    let segueIdToSharesView :String = "toSharesPage"
    
    /// Segue id to LAN OTA
    let segueIdToLANOTA = "toLANOTA"
    
    /// The session manager which retains device manager of device list showing on this table view.
    var sessionManager :AylaSessionManager?
    
    /// View model used by view controller to present device list.
    var viewModel : DeviceListViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
        
        if let sessionManager = sessionManager {
            viewModel = DeviceListViewModel(deviceManager: sessionManager.deviceManager, tableView: tableView)
            viewModel?.delegate = self
            if sessionManager.cachedSession {
                UIAlertController.alert("Offline Mode", message: "Logged in LAN Mode, some features might not be available", buttonTitle: "OK", fromController: self)
            }
        }
        else {
            print(" - WARNING - device list with a nil session manager")
            // TODO: present a warning and give fresh option
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    @IBAction func rightBarButtonTapped(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Register a Device", style: .Default, handler: { (action) -> Void in
            self.performSegueWithIdentifier(self.segueIdToRegisterView, sender: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Wi-Fi Setup", style: .Default, handler: { (action) -> Void in
            let setupStoryboard: UIStoryboard = UIStoryboard(name: "Setup", bundle: nil)
            let setupVC = setupStoryboard.instantiateInitialViewController()
            self.navigationController?.presentViewController(setupVC!, animated: true, completion:nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "View Device Shares", style: .Default, handler: { (action) -> Void in
            self.performSegueWithIdentifier(self.segueIdToSharesView, sender: nil)
        }))
        let lanOTA = UIAlertAction(title: "LAN OTA", style: .Default) { (action) in
            self.performSegueWithIdentifier(self.segueIdToLANOTA, sender: nil)
        }
        actionSheet.addAction(lanOTA)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Device list view delegate

    func deviceListViewModel(viewModel: DeviceListViewModel, didSelectDevice device: AylaDevice) {
        if device.isKindOfClass(AylaBLEDevice.self) {
            let localDevice = device as! AylaBLEDevice
            if localDevice.requiresLocalConfiguration {
                let alert = UIAlertController(title: "Configure Local Connection", message: "This device requires additional setup to allow your mobile device to reach it. Would you like to configure this device now?", preferredStyle: .Alert)
                
                let configureDeviceAction = UIAlertAction(title: "Yes", style: .Default, handler: { (alert) in
                    if let localDeviceManager = AylaNetworks.shared().getPluginWithId(PLUGIN_ID_LOCAL_DEVICE) as? AylaLocalDeviceManager {
                        localDeviceManager.findLocalDevicesWithHint(nil, timeout: 5000, success: { (candidates) in
                            
                            let connectToCandidate: (AylaBLECandidate) -> Void = { candidate in
                                localDevice.mapToIdentifier(candidate.peripheral.identifier)
                                localDevice.connectLocalWithSuccess({
                                    
                                    self.performSegueWithIdentifier(self.segueIdToGrillRight, sender: device)
                                    }, failure: { (error) in
                                        UIAlertController.alert("Could not connect to device", message: "Error: \(error.localizedDescription)", buttonTitle: "OK", fromController: self)
                                })
                            }
                            
                            if candidates.count == 0 {
                                UIAlertController.alert(nil, message: "Unable to find this device. Please make sure the device is turned on and you are nearby.", buttonTitle: "OK", fromController: self)
                            } else if candidates.count == 1 {
                                let candidate = candidates.first! as! AylaBLECandidate
                                connectToCandidate(candidate)
                                
                            } else {
                                let strings = candidates.map({ (candidate) -> String in
                                    let candidate = candidate as! AylaBLECandidate
                                    
                                    return "\(candidate.oemModel ?? "Candidate"): \(candidate.peripheral.identifier.UUIDString)"
                                })
                                ActionSheetStringPicker.showPickerWithTitle("Select the device", rows: strings, initialSelection: 0, doneBlock: { (picker, index, uuidString) in
                                    let candidate = candidates[index]
                                    connectToCandidate(candidate as! AylaBLECandidate)
                                    }, cancelBlock: { _ in }, origin: self.view)
                            }
                            }, failure: { (error) in
                                UIAlertController.alert(nil, message: "Unable to find devices: \(error.localizedDescription).", buttonTitle: "OK", fromController: self)
                        })
                    }
                })
                alert.addAction(configureDeviceAction)
                alert.addAction(UIAlertAction(title: "No, thanks", style: .Cancel, handler: { _ in
                    self.performSegueWithIdentifier(self.segueIdToGrillRight, sender: device)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                
                return
            }
            
            self.performSegueWithIdentifier(segueIdToGrillRight, sender: device)
            return
        }
        
        self.performSegueWithIdentifier(segueIdToDevice, sender: device)
    }
    
    func deviceListViewModel(viewModel: DeviceListViewModel, lanOTAWithDevice device: AylaDevice) {
        // Swith to LAN OTA page
        self.performSegueWithIdentifier(segueIdToLANOTA, sender: device)
    }
    
    func deviceListViewModel(viewModel: DeviceListViewModel, didUnregisterDevice device: AylaDevice){
        let deviceViewModel = DeviceViewModel(device: device, panel: nil, propertyListTableView: nil, sharesModel: self.viewModel!.sharesModel)
        deviceViewModel.unregisterDeviceWithConfirmation(self, successHandler: {
            self.tableView.reloadData()
            }, failureHandler: { (error) in
                self.tableView.reloadData()
        })
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdToDevice { // To device page
            if let device = sender as? AylaDevice {
                let vc = segue.destinationViewController as! DeviceViewController
                vc.device = device
                vc.sharesModel = self.viewModel?.sharesModel
            }
        } else if segue.identifier == segueIdToGrillRight {
            if let device = sender as? GrillRightDevice {
                let vc = segue.destinationViewController as! GrillRightViewController
                vc.device = device
                vc.sharesModel = self.viewModel?.sharesModel
            }
        } else if segue.identifier == segueIdToRegisterView { // To registration page
        }
        else if segue.identifier == segueIdToLANOTA {
            if let device = sender as? AylaDevice, sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
                let otaDevice = AylaLANOTADevice(sessionManager: sessionManager, DSN: device.dsn!, lanIP: device.lanIp!)
                let vc = segue.destinationViewController as! LANOTAViewController
                vc.device = otaDevice
            }
        }
    }
    
}
