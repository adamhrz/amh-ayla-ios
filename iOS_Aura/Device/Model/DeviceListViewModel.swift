//
//  DeviceListViewModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK
import Ayla_LocalDevice_SDK

protocol DeviceListViewModelDelegate: class {
    func deviceListViewModel(viewModel:DeviceListViewModel, didSelectDevice device:AylaDevice)
    func deviceListViewModel(viewModel:DeviceListViewModel, lanOTAWithDevice device:AylaDevice)
    func deviceListViewModel(viewModel:DeviceListViewModel, didUnregisterDevice device:AylaDevice)
}

class DeviceListViewModel:NSObject, UITableViewDataSource, UITableViewDelegate, AylaDeviceManagerListener, AylaDeviceListener {

    /// Device manager where deivce list belongs
    let deviceManager: AylaDeviceManager
    
    /// Table view of devices
    var tableView: UITableView
    
    /// Devices which are being represented in table view.
    var devices : [ AylaDevice ]
    
    var sharesModel : DeviceSharesModel?

    weak var delegate: DeviceListViewModelDelegate?
    
    static let DeviceCellId: String = "DeviceCellId"
    static let LocalDeviceCellId: String = "LocalDeviceCellId";
    
    required init(deviceManager: AylaDeviceManager, tableView: UITableView) {
        
        self.deviceManager = deviceManager
        
        // Init device list as empty
        self.devices = []
        
        self.tableView = tableView

        super.init()
        self.sharesModel = DeviceSharesModel(deviceManager: deviceManager)
        
        // Add self as device manager listener
        deviceManager.addListener(self)
        
        // Add self as delegate and datasource of input table view.
        tableView.dataSource = self
        tableView.delegate = self
        
        // Update device list with device manager.
        self.updateDeviceListFromDeviceManager()
    }
    
    func updateDeviceListFromDeviceManager() {
        devices = self.deviceManager.devices.values.map({ (device) -> AylaDevice in
            return device as! AylaDevice
        })
        tableView.reloadData()
    }
    
    // MARK: Table View Data Source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let device = self.devices[indexPath.row]
        let cellId = device is AylaLocalDevice ? DeviceListViewModel.LocalDeviceCellId : DeviceListViewModel.DeviceCellId
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId) as? DeviceTVCell
        
        if (cell != nil) {
            cell!.configure(device)
        }
        else {
            assert(false, "\(cellId) - reusable cell can't be dequeued'")
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let lanOTAAction = UITableViewRowAction(style: .Default, title: "LAN OTA") { (action, indexPath) in
            let device = self.devices[indexPath.row]
            self.delegate?.deviceListViewModel(self, lanOTAWithDevice: device)
        }
        lanOTAAction.backgroundColor = UIColor.auraLeafGreenColor();
        
        let unregisterAction = UITableViewRowAction(style: .Default, title: "Unregister") { (action, indexPath) in
            let device = self.devices[indexPath.row]
            self.delegate?.deviceListViewModel(self, didUnregisterDevice: device)
        }
        unregisterAction.backgroundColor = UIColor.auraRedColor()
        return [lanOTAAction, unregisterAction]
    }
    
    // MARK: Table View Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let device = self.devices[indexPath.row]
        self.delegate?.deviceListViewModel(self, didSelectDevice: device)
    }
    
    // MARK - device manager listener
    func deviceManager(deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : NSError]) {
        print("Init complete")
        self.updateDeviceListFromDeviceManager()
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

        self.updateDeviceListFromDeviceManager()
    }
    
    func deviceManager(deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState) {
        print("Change in deviceManager state: new state \(newState), was \(oldState)")
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        if change.isKindOfClass(AylaDeviceChange) {
            // Not a good udpate strategy
            self.updateDeviceListFromDeviceManager()
        }
    }
    
    func device(device: AylaDevice, didFail error: NSError) {
        // Device errors are not handled here.
    }
}
