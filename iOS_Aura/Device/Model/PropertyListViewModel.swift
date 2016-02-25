//
//  PropertyListViewModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class PropertyListViewModel: NSObject, UITableViewDataSource, AylaDeviceListener {
    
    /// Defaule property cell id
    static let PropertyCellId: String = "PropertyCellId"
    
    /// Device
    let device: AylaDevice
    
    /// Table view of properties
    var tableView: UITableView
    
    /// Properties which are being represented in table view.
    var properties : [ AylaProperty ]
    
    required init(device: AylaDevice, tableView: UITableView) {
        
        self.device = device
        self.properties = []
        
        self.tableView = tableView
        
        super.init()
        
        // Add self as device listener
        device.addListener(self)
        
        tableView.dataSource = self
        self.updatePropertyListFromDevice()
    }
    
    /**
     Use this method to reload property list from device.
     */
    func updatePropertyListFromDevice() {
        
        if let knownProperties = self.device.properties {
            self.properties = knownProperties.values.map({ (property) -> AylaProperty in
                return property as! AylaProperty
            }).sort({ (prop1, prop2) -> Bool in
                // Do a sort to the property list based on property names.
                return prop1.name < prop2.name
            })
        }
        else {
            // No properties list found in device
            self.properties = []
        }
        
        tableView.reloadData()
    }
    
    // MARK: Table View Data Source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.properties.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellId = PropertyListViewModel.PropertyCellId
        let item = self.properties[indexPath.row] as AylaProperty
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId) as? PropertyTVCell
        
        if (cell != nil) {
            cell?.configure(item)
        }
        else {
            assert(false, "\(cellId) - reusable cell can't be dequeued'")
        }
        
        return cell!
    }
    
    // MARK - device listener
    
    func device(device: AylaDevice, didFail error: NSError) {
        // We do nothing to handle device errors here.
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        // Not a smart way to update.
        if(change.isKindOfClass(AylaPropertyChange)) {
            log("Obverse changes: \(change)", isWarning: false)
            self.updatePropertyListFromDevice()
        }
    }
}
