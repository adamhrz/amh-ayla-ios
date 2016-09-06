//
//  AuraConfig.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

class AuraConfig {
    class AuraDeviceConfig {
        var dsn :String?
        var oemModel :String?
        var model :String?
        var managedProperties :Array<String>?
        
        init (dsn :String, oemModel :String, model :String, managedProperties :Array<String>) {
            self.dsn = dsn
            self.oemModel = oemModel
            self.model = model
            self.managedProperties = managedProperties
        }
        
        func toDictionary() -> NSDictionary {
            let dictionary = NSMutableDictionary()
            if let model = model {
                dictionary["model"] = model
            }
            if let oemModel = oemModel {
                dictionary["oemModel"] = oemModel
            }
            if let dsn = dsn {
                dictionary["dsn"] = dsn
            }
            if let managedProperties = managedProperties {
                dictionary["managedProperties"] = managedProperties
            }
            return dictionary
        }
    }
    
    static let KeyCurrentConfig = "current_config"
    static let KeyCurrentConfigName = "current_config_name"
    
    static let ConfigNameUSDev   = "US Development"
    static let ConfigNameUSField = "US Field"
    static let ConfigNameCNDev   = "CN Development"
    static let ConfigNameCNField = "CN Field"
    
    static let configUSDev = ["appId": AuraOptions.AppIdUSDev, "appSecret": AuraOptions.AppSecretUSDev, "serviceType": "Development", "serviceLocation": "US"]
    static let configUSField = ["appId": AuraOptions.AppIdUSField, "appSecret": AuraOptions.AppSecretUSField, "serviceType": "Field", "serviceLocation": "US"]
    static let configCNDev = ["appId": AuraOptions.AppIdCNDev, "appSecret": AuraOptions.AppSecretCNDev, "serviceType": "Development", "serviceLocation": "CN"]
    static let configCNField = ["appId": AuraOptions.AppIdCNField, "appSecret": AuraOptions.AppSecretCNField, "serviceType": "Field", "serviceLocation": "CN"]
    
    static let availableConfigurations = [
        AuraConfig(name: ConfigNameUSDev, config: configUSDev),
        AuraConfig(name: ConfigNameUSField, config: configUSField),
        AuraConfig(name: ConfigNameCNDev, config: configCNDev),
        AuraConfig(name: ConfigNameCNField, config: configCNField),
    ]
    
    /**
     Save AuraConfig to UserDefaults
     */
    static func saveConfig(config: AuraConfig) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(config.name, forKey: KeyCurrentConfigName)
        defaults.setObject(config.config, forKey: KeyCurrentConfig)
    }
    
    /**
     Get current saved Aura Config. If no configs saved, return US Development Config.
     */
    static func currentConfig() -> AuraConfig {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let savedConfig = defaults.objectForKey(KeyCurrentConfig) as? NSDictionary,
            let configName = defaults.stringForKey(KeyCurrentConfigName) {
            return AuraConfig(name: configName, config: savedConfig)
        }
        else {
            return availableConfigurations[0]
        }
    }
    
    var name:String!
    var config:NSDictionary!
    
    init (name:String, config:NSDictionary) {
        self.name = name
        self.config = config
    }
    
    func applyTo(settings: AylaSystemSettings) {
        settings.appId = config["appId"] as! String
        settings.appSecret = config["appSecret"] as! String
        
        if let type = config["serviceType"] as? String {
            switch type {
            case "Dynamic":
                settings.serviceType = .Dynamic
                
            case "Field":
                settings.serviceType = .Field
                
            case "Staging":
                settings.serviceType = .Staging
                
            default:
                settings.serviceType = .Development
            }
        }
        
        if let location = config["serviceLocation"] as? String {
            switch location {
            case "CN", "China":
                settings.serviceLocation = .CN
                
            case "EU", "Europe":
                settings.serviceLocation = .EU
                
            default:
                settings.serviceLocation = .US
            }
        }
        
        if let allowDSS = config["allowDSS"] as? Bool {
            settings.allowDSS = allowDSS
        }
        if let allowOfflineUse = config["allowOfflineUse"] as? Bool {
            settings.allowOfflineUse = allowOfflineUse
        }
        if let defaultNetworkTimeoutMs = config["defaultNetworkTimeoutMs"] as? Int {
            settings.defaultNetworkTimeout = Double(defaultNetworkTimeoutMs / 1000)
        }
    }
    
    static func createConfig(name:String, fromSettings settings:AylaSystemSettings, devices:Array<AuraDeviceConfig>?) throws -> NSData? {
        guard let inmutableConfig = settings.toConfigDictionary(name)
            else {
                return nil
        }
        let config = NSMutableDictionary(dictionary: inmutableConfig)
        
        guard let devices = devices
            else {
                return try NSJSONSerialization.dataWithJSONObject(config, options: .PrettyPrinted)
        }
        
        config["managedDevices"] = devices
        
        return try NSJSONSerialization.dataWithJSONObject(config, options: .PrettyPrinted)
    }
}