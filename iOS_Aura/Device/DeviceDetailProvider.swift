//
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

class DeviceDetailProvider: NSObject, AylaDeviceDetailProvider {
    func monitoredPropertyNamesForDevice(device: AylaDevice) -> [AnyObject]? {
        if let propertyNames = device.properties?.keys {
            return Array(propertyNames);
        }
        return nil;
    }
}