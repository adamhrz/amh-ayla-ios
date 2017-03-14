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
    private let logTag = "DeviceListTVController"
    
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

        sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)
        
        if let sessionManager = sessionManager {
            viewModel = DeviceListViewModel(deviceManager: sessionManager.deviceManager, tableView: tableView)
            viewModel?.delegate = self
            if sessionManager.isCachedSession {
                UIAlertController.alert("Offline Mode", message: "Logged in LAN Mode, some features might not be available", buttonTitle: "OK", fromController: self)
            }
        }
        else {
            AylaLogW(tag: logTag, flag: 0, message:"device list with a nil session manager")
            // TODO: present a warning and give fresh option
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    @IBAction func rightBarButtonTapped(_ sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Register a Device", style: .default, handler: { (action) -> Void in
            self.performSegue(withIdentifier: self.segueIdToRegisterView, sender: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Wi-Fi Setup", style: .default, handler: { (action) -> Void in
            let setupStoryboard: UIStoryboard = UIStoryboard(name: "Setup", bundle: nil)
            let setupVC = setupStoryboard.instantiateInitialViewController()
            self.navigationController?.present(setupVC!, animated: true, completion:nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "View Device Shares", style: .default, handler: { (action) -> Void in
            self.performSegue(withIdentifier: self.segueIdToSharesView, sender: nil)
        }))
        let lanOTA = UIAlertAction(title: "LAN OTA", style: .default) { (action) in
            self.performSegue(withIdentifier: self.segueIdToLANOTA, sender: nil)
        }
        actionSheet.addAction(lanOTA)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Device list view delegate

    func deviceListViewModel(_ viewModel: DeviceListViewModel, didSelectDevice device: AylaDevice) {
        if device.isKind(of: AylaBLEDevice.self) {
            let localDevice = device as! AylaBLEDevice
            if localDevice.requiresLocalConfiguration {
                let alert = UIAlertController(title: "Configure Local Connection", message: "This device requires additional setup to allow your mobile device to reach it. Would you like to configure this device now?", preferredStyle: .alert)
                
                let configureDeviceAction = UIAlertAction(title: "Yes", style: .default, handler: { (alert) in
                    if let localDeviceManager = AylaNetworks.shared().getPluginWithId(PLUGIN_ID_LOCAL_DEVICE) as? AylaLocalDeviceManager {
                        localDeviceManager.findLocalDevices(withHint: nil, timeout: 5000, success: { (candidates) in
                            
                            let connectToCandidate: (AylaBLECandidate) -> Void = { candidate in
                                localDevice.map(toIdentifier: candidate.peripheral.identifier)
                                localDevice.connectLocal(success: {
                                    
                                    self.performSegue(withIdentifier: self.segueIdToGrillRight, sender: device)
                                    }, failure: { (error) in
                                        UIAlertController.alert("Could not connect to device", message: "Error: \(error.description)", buttonTitle: "OK", fromController: self)
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
                                    
                                    return "\(candidate.oemModel ?? "Candidate"): \(candidate.peripheral.identifier.uuidString)"
                                })
                                ActionSheetStringPicker.show(withTitle: "Select the device", rows: strings, initialSelection: 0, doneBlock: { (picker, index, uuidString) in
                                    let candidate = candidates[index]
                                    connectToCandidate(candidate as! AylaBLECandidate)
                                    }, cancel: { _ in }, origin: self.view)
                            }
                            }, failure: { (error) in
                                UIAlertController.alert(nil, message: "Unable to find devices: \(error.localizedDescription).", buttonTitle: "OK", fromController: self)
                        })
                    }
                })
                alert.addAction(configureDeviceAction)
                alert.addAction(UIAlertAction(title: "No, thanks", style: .cancel, handler: { _ in
                    self.performSegue(withIdentifier: self.segueIdToGrillRight, sender: device)
                }))
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            self.performSegue(withIdentifier: segueIdToGrillRight, sender: device)
            return
        }
        
        self.performSegue(withIdentifier: segueIdToDevice, sender: device)
    }
    
    func deviceListViewModel(_ viewModel: DeviceListViewModel, lanOTAWithDevice device: AylaDevice) {
        // Swith to LAN OTA page
        self.performSegue(withIdentifier: segueIdToLANOTA, sender: device)
    }
    
    func deviceListViewModel(_ viewModel: DeviceListViewModel, didUnregisterDevice device: AylaDevice){
        let deviceViewModel = DeviceViewModel(device: device, panel: nil, propertyListTableView: nil, sharesModel: self.viewModel!.sharesModel)
        deviceViewModel.unregisterDeviceWithConfirmation(self, successHandler: {
            self.tableView.reloadData()
            }, failureHandler: { (error) in
                self.tableView.reloadData()
        })
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdToDevice { // To device page
            if let device = sender as? AylaDevice {
                let vc = segue.destination as! DeviceViewController
                vc.device = device
                vc.sharesModel = self.viewModel?.sharesModel
            }
        } else if segue.identifier == segueIdToGrillRight {
            if let device = sender as? GrillRightDevice {
                let vc = segue.destination as! GrillRightViewController
                vc.device = device
                vc.sharesModel = self.viewModel?.sharesModel
            }
        } else if segue.identifier == segueIdToRegisterView { // To registration page
        }
        else if segue.identifier == segueIdToLANOTA {
            if let device = sender as? AylaDevice, let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName) {
                let otaDevice = AylaLANOTADevice(sessionManager: sessionManager, dsn: device.dsn!, lanIP: device.lanIp!)
                let vc = segue.destination as! LANOTAViewController
                vc.device = otaDevice
            }
        }
    }
    
}
