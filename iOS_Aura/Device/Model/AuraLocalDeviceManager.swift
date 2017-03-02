//
//  AuraLocalDeviceManager.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 12/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import CoreBluetooth
import Ayla_LocalDevice_SDK

class AuraLocalDeviceManager: AylaBLEDeviceManager {
    override init() {
        super.init(services: [AuraLocalDeviceManager.SERVICE_GRILL_RIGHT, CBUUID(string: SERVICE_AYLA_BLE)])
    }
    static let PLUGIN_ID_LOCAL_DEVICE = "com.aylanetworks.aylasdk.localdevice"
    enum DeviceManagerError: Error {
        case emptyServiceArray
    }
    static let SERVICE_GRILL_RIGHT = CBUUID(string: GrillRightDevice.SERVICE_GRILL_RIGHT)
    
    override func deviceClass(forModel model: String, oemModel: String, uniqueId: String) -> AnyClass? {
        if model.compare(GrillRightDevice.GRILL_RIGHT_MODEL) == .orderedSame {
            return GrillRightDevice.self
        }
        return super.deviceClass(forModel: model, oemModel: oemModel, uniqueId: uniqueId)
    }
    
    override func createLocalCandidate(_ peripheral: CBPeripheral, advertisementData: [String : Any], rssi: Int) -> AylaBLECandidate {
        let serviceUUIDs = advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID];
        for service in serviceUUIDs {
            if service.isEqual(AuraLocalDeviceManager.SERVICE_GRILL_RIGHT) {
                let device = GrillRightCandidate(peripheral: peripheral,advertisementData: advertisementData,rssi: rssi,bleDeviceManager: self)
                return device
            }
        }
        return super.createLocalCandidate(peripheral, advertisementData: advertisementData, rssi: rssi)
    }
}
