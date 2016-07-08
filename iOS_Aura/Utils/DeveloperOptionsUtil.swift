//
//  DeveloperOptionsUtil.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

class DeveloperOptionsUtil {
    
    /**
     Get `AylaSystemSettings` object base on the given service location and type.
     
     - parameter location: Service location: 0 - US, 1 - CN, 2 - EU
     - parameter service:  Service type: 0 - Development, 1 - Field, 3 - Staging
     
     - returns: AylaSystemSettings object with following properties set: App Id/Secret, service location/type.
     */
    static func systemSettingsWithLocation(location: AylaServiceLocation, service: AylaServiceType) -> AylaSystemSettings {
        let settings = AylaNetworks.shared().systemSettings
        
        if (service == .Development) { // Development
            settings.serviceType = .Development
            switch (location) {
            case .US:
                settings.serviceLocation = .US
                settings.appId = AuraOptions.AppIdUSDev
                settings.appSecret = AuraOptions.AppSecretUSDev
            case .CN:
                settings.serviceLocation = .CN
                settings.appId = AuraOptions.AppIdCNDev
                settings.appSecret = AuraOptions.AppSecretCNDev
            case .EU:
                settings.serviceLocation = .EU
                settings.appId = AuraOptions.AppIdEUDev
                settings.appSecret = AuraOptions.AppSecretEUDev
            }
        }
        else if (service == .Field) {
            settings.serviceType = .Field
            switch (location) {
            case .US:
                settings.serviceLocation = .US
                settings.appId = AuraOptions.AppIdUSField
                settings.appSecret = AuraOptions.AppSecretUSField
            case .CN:
                settings.serviceLocation = .CN
                settings.appId = AuraOptions.AppIdCNField
                settings.appSecret = AuraOptions.AppSecretCNField
            case .EU:
                settings.serviceLocation = .EU
                settings.appId = AuraOptions.AppIdEUField
                settings.appSecret = AuraOptions.AppSecretEUField
            }
        }
        else if (service == .Staging) {
            settings.serviceType = .Staging
            // Staging service is only located in the USA
            settings.appId = AuraOptions.AppIdStaging
            settings.appSecret = AuraOptions.AppSecretStaging
        }
        
        return settings
    }
}