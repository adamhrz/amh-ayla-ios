//
//  AylaDevice_extensions.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

extension AylaDevice {

    func getProperty(name: String) -> AylaProperty? {
        if let properties = self.properties as? [String: AylaProperty]{
            return properties[name]
        }
        return nil
    }
    
    func managedPropertyNames() -> Array<String>? {
        // Get managed properties from device detail provider
        let array = AylaNetworks.shared().systemSettings.deviceDetailProvider.monitoredPropertyNamesForDevice(self) as? [String]
        return array
    }

}
