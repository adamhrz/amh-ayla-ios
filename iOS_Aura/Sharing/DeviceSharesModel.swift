//
//  DeviceSharesModel.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/6/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//


import iOS_AylaSDK


protocol DeviceSharesModelDelegate: class {
    func deviceSharesModel(model:DeviceSharesModel, receivedSharesListDidUpdate: ((shares :[AylaShare]) -> Void)?)
    func deviceSharesModel(model:DeviceSharesModel, ownedSharesListDidUpdate: ((shares :[AylaShare]) -> Void)?)
    
}

class DeviceSharesModel:NSObject, AylaDeviceManagerListener, AylaDeviceListener {
    
    /// Device manager where device list belongs
    let deviceManager: AylaDeviceManager

    var ownedShares : [ AylaShare ]
    var receivedShares : [ AylaShare ]
    var devices : [ AylaDevice ]
    
    weak var delegate: DeviceSharesModelDelegate?
    
    required init(deviceManager: AylaDeviceManager) {
        
        self.deviceManager = deviceManager
        
        self.ownedShares = []
        self.receivedShares = []
        self.devices = []
        
        super.init()
        self.updateSharesList(nil, failureHandler: nil)
        
        // Add self as device manager listener
        deviceManager.addListener(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DeviceSharesModel.refreshShares), name: AuraNotifications.SharesChanged, object: nil)
        self.refreshDeviceList()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func deviceForShare(share: AylaShare) -> AylaDevice? {
        for device in devices {
            if share.resourceId == device.dsn {
                return device
            }
        }
        return nil
    }
    
    func ownedSharesForDevice(device: AylaDevice) -> [AylaShare]? {
        var sharesArray = [AylaShare]()
        for share in self.ownedShares {
            if device.dsn == share.resourceId {
                sharesArray.append(share)
            }
        }
        return sharesArray
    }
    
    func receivedShareForDevice(device: AylaDevice) -> AylaShare? {
        for share in self.receivedShares {
            if device.dsn == share.resourceId {
                return share
            }
        }
        return nil
    }
    
    
    func refreshDeviceList(){
        devices = self.deviceManager.devices.values.map({ (device) -> AylaDevice in
            return device as! AylaDevice
        })
    }
    
    func refreshShares(){
        self.updateSharesList({ (shares) in }) { (error) in }
    }
    
    func updateSharesList(successHandler: ((shares :[AylaShare]) -> Void)?, failureHandler: ((error: NSError) -> Void)?) {
        deviceManager.sessionManager?.fetchReceivedSharesWithResourceName(AylaShareResourceNameDevice, resourceId: nil, expired: false, accepted: true, success: { (shares: [AylaShare]) in
                /*if self.receivedShares == shares {
                    print("Received Shares Update contains no changes.")
                } else { */
                    self.receivedShares = shares
                    self.delegate?.deviceSharesModel(self, receivedSharesListDidUpdate: { (shares) in })
                    if let successHandler = successHandler { successHandler(shares: shares) }
            // }
            
            }, failure: { (error :NSError) in
                print("Failure to receive shares: $@", error.description)
                if let failureHandler = failureHandler { failureHandler(error: error) }
            }
        )
        deviceManager.sessionManager?.fetchOwnedSharesWithResourceName(AylaShareResourceNameDevice, resourceId: nil, expired: false, accepted: true, success: { (shares: [AylaShare]) in
            // if self.ownedShares == shares {
            //       print("Owned Shares Update contains no changes.")
            // } else {
                    self.ownedShares = shares
                    self.delegate?.deviceSharesModel(self, ownedSharesListDidUpdate: { (shares) in })
                    if let successHandler = successHandler { successHandler(shares: shares) }
            //   }
            }, failure: { (error :NSError) in
                print("Failure to receive shares: $@", error.description)
                if let failureHandler = failureHandler { failureHandler(error: error) }
            }
        )
    }
    
    // MARK - device manager listener
    func deviceManager(deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : NSError]) {
        print("Init complete")
        self.updateSharesList(nil, failureHandler: nil)
        self.refreshDeviceList()
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
        //self.updateSharesList(nil, failureHandler: nil)
        self.refreshDeviceList()
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        if change.isKindOfClass(AylaDeviceChange) || change.isKindOfClass(AylaDeviceListChange) {
            // Not a good udpate strategy
            self.updateSharesList(nil, failureHandler: nil)
            self.refreshDeviceList()
        }
    }
    
    func device(device: AylaDevice, didFail error: NSError) {
        // Device errors are not handled here.
    }
}