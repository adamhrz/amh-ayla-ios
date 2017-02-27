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
    enum DeviceManagerError: ErrorType {
        case EmptyServiceArray
    }
    static let SERVICE_GRILL_RIGHT = CBUUID(string: GrillRightDevice.SERVICE_GRILL_RIGHT)
    
    override func deviceClassForModel(model: String, oemModel: String, uniqueId: String) -> AnyClass? {
        if model.compare(GrillRightDevice.GRILL_RIGHT_MODEL) == .OrderedSame {
            return GrillRightDevice.self
        }
        return super.deviceClassForModel(model, oemModel: oemModel, uniqueId: uniqueId)
    }
    
    override func createLocalCandidate(peripheral: CBPeripheral, advertisementData: [String : AnyObject], rssi: Int) -> AylaBLECandidate {
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
