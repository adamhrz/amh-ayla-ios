//
//  DeviceListViewModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

protocol DeviceListViewModelDelegate: class {
    func deviceListViewModel(viewModel:DeviceListViewModel, didSelectDevice device:AylaDevice)
}

class DeviceListViewModel:NSObject, UITableViewDataSource, UITableViewDelegate, AylaDeviceManagerListener, AylaDeviceListener {

    /// Device manager where deivce list belongs
    let deviceManager: AylaDeviceManager
    
    /// Table view of devices
    var tableView: UITableView
    
    /// Devices which are being represented in table view.
    var devices : [ AylaDevice ]

    weak var delegate: DeviceListViewModelDelegate?
    
    static let DeviceCellId: String = "DeviceCellId"
    
    required init(deviceManager: AylaDeviceManager, tableView: UITableView) {
        
        self.deviceManager = deviceManager
        
        // Init device list as empty
        self.devices = []
        
        self.tableView = tableView

        super.init()
        
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier(DeviceListViewModel.DeviceCellId) as? DeviceTVCell
        
        if (cell != nil) {
            cell!.configure(device)
        }
        else {
            assert(false, "\(DeviceListViewModel.DeviceCellId) - reusable cell can't be dequeued'")
        }
        
        return cell!
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