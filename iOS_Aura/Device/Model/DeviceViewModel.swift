//
//  DeviceListViewModel.swift
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

    /// Property list model view
    let propertyListViewModel :PropertyListViewModel?
    
    /// Device representd by this view model
    let device: AylaDevice
    
    required init(device:AylaDevice, panel:DevicePanelView?, propertyListTableView: UITableView?) {
        self.devicePanel = panel
        self.device = device
        
        if let tv = propertyListTableView {
            // If a table view has been passed in, create a property list view model and assign the input tableview to it.
            self.propertyListViewModel = PropertyListViewModel(device: device, tableView: tv)
        } else {
            self.propertyListViewModel = nil
        }
        
        super.init()
        
        device.addListener(self)
        self.update()
    }
    
    func update() {
        devicePanel?.configure(device)
    }
    
    // MARK - device manager listener
    func device(device: AylaDevice, didFail error: NSError) {
        print("- WARNING - an error happened on device \(error)")
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        self.update()
    }
}