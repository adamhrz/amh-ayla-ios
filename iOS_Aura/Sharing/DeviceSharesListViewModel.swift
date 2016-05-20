//
//  DeviceSharesListViewModel.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/5/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK

protocol DeviceSharesListViewModelDelegate: class {
    func deviceSharesListViewModel(viewModel:DeviceSharesListViewModel, didDeleteShare share:AylaShare)
    func deviceSharesListViewModel(viewModel:DeviceSharesListViewModel, didSelectShare share:AylaShare)

}

class DeviceSharesListViewModel:NSObject, UITableViewDataSource, UITableViewDelegate, AylaDeviceManagerListener, AylaDeviceListener {
    
    /// Device manager where device list belongs
    let deviceManager: AylaDeviceManager
    
    /// Table view of devices
    var tableView: UITableView?
    
    var sharesModel: DeviceSharesModel?
    
    var expandedRow: NSIndexPath?
    
    static let DeviceShareCellId: String = "DeviceShareCellId"
    
    enum SharesTableSection: Int {
        case OwnedShares = 0
        case ReceivedShares
    }
    
    weak var delegate: DeviceSharesListViewModelDelegate?

    
    required init(deviceManager: AylaDeviceManager, tableView: UITableView) {
        
        self.deviceManager = deviceManager
        
        self.tableView = tableView
        
        self.sharesModel = DeviceSharesModel(deviceManager: self.deviceManager)
        super.init()
        
        self.sharesModel!.updateSharesList({ (shares) in
            self.tableView?.reloadData()
            }) { (error) in
        }
        // Add self as device manager listener
        deviceManager.addListener(self)
        
        // Add self as delegate and datasource of input table view.
        tableView.dataSource = self
        tableView.delegate = self
        
        self.sharesModel!.refreshDeviceList()
    }
    
    // MARK: Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SharesTableSection.OwnedShares.rawValue{
            return self.sharesModel!.ownedShares.count
        } else if section == SharesTableSection.ReceivedShares.rawValue {
            return self.sharesModel!.receivedShares.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SharesTableSection.OwnedShares.rawValue{
            return "Devices You Own"
        } else if section == SharesTableSection.ReceivedShares.rawValue {
            return "Devices Shared to You"
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var share: AylaShare?
        if indexPath.section == SharesTableSection.OwnedShares.rawValue {
            share = self.sharesModel!.ownedShares[indexPath.row]
        } else if indexPath.section == SharesTableSection.ReceivedShares.rawValue {
            share = self.sharesModel!.receivedShares[indexPath.row]
        } else {
            assert(false, "Share for section \(indexPath.section), row \(indexPath.row) does not exist")
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(DeviceSharesListViewModel.DeviceShareCellId) as? DeviceShareTVCell
        
        if (cell != nil) {
            let expand : Bool
            if let row = self.expandedRow {
                expand = row == indexPath ? true : false
            } else {
                expand = false
            }
            let device = self.sharesModel!.deviceForShare(share!)
            cell!.configure(share!, device: device, expanded:expand)
        }
        else {
            assert(false, "\(DeviceSharesListViewModel.DeviceShareCellId) - reusable cell can't be dequeued'")
        }
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let cellPath = self.expandedRow {
            if cellPath == indexPath{
                return DeviceShareTVCell.expandedRowHeight
            }
        }
        return DeviceShareTVCell.collapsedRowHeight
    }
    
    
    // MARK: Table View Delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var share: AylaShare?
        if indexPath.section == SharesTableSection.OwnedShares.rawValue {
            share = self.sharesModel!.ownedShares[indexPath.row]
        } else if indexPath.section == SharesTableSection.ReceivedShares.rawValue {
            share = self.sharesModel!.receivedShares[indexPath.row]
        } else {
            assert(false, "Share for section \(indexPath.section), row \(indexPath.row) does not exist")
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        var rowsToReload : [NSIndexPath]
        if self.expandedRow == nil {
            self.expandedRow = indexPath
            rowsToReload = [self.expandedRow!]
        } else if self.expandedRow == indexPath {
            self.expandedRow = nil
            rowsToReload = [indexPath]
        } else {
            rowsToReload = [self.expandedRow!, indexPath]
            self.expandedRow = indexPath
        }
        
        tableView.reloadRowsAtIndexPaths(rowsToReload, withRowAnimation: UITableViewRowAnimation.Fade)
        self.delegate?.deviceSharesListViewModel(self, didSelectShare: share!)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let unshareAction = UITableViewRowAction(style: .Default, title: "Unshare") { (action, indexPath) in
            var share: AylaShare?
            if indexPath.section == SharesTableSection.OwnedShares.rawValue {
                share = self.sharesModel!.ownedShares[indexPath.row]
            } else if indexPath.section == SharesTableSection.ReceivedShares.rawValue {
                share = self.sharesModel!.receivedShares[indexPath.row]
            }
            self.delegate?.deviceSharesListViewModel(self, didDeleteShare: share!)
            self.expandedRow = nil
            tableView.reloadData()
        }
        unshareAction.backgroundColor = UIColor.auraRedColor()
        return [unshareAction]
    }
    
    
    // MARK - Device Manager Listener
    func deviceManager(deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : NSError]) {
        print("Init complete")
        self.sharesModel!.updateSharesList({ (shares) in
            self.tableView?.reloadData()
        }) { (error) in }
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
        
        self.sharesModel!.updateSharesList({ (shares) in
            self.tableView?.reloadData()
        }) { (error) in }
    }
    
    func deviceManager(deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState){
        
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        if change.isKindOfClass(AylaDeviceChange) || change.isKindOfClass(AylaDeviceListChange) {
            // Not a good long term update strategy
            
            self.sharesModel!.updateSharesList({ (shares) in
                self.tableView?.reloadData()
            }) { (error) in }
        }
        
    }
    
    func device(device: AylaDevice, didFail error: NSError) {
        // Device errors are not currently handled here.
    }
}