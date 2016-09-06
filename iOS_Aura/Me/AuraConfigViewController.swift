//
//  AuraConfigViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 9/2/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class AuraConfigViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var appIdTextField: UITextField!
    @IBOutlet weak var appSecretTextField: UITextField!
    @IBOutlet weak var serviceTypePicker: UIPickerView!
    @IBOutlet weak var serviceLocationPicker: UIPickerView!
    @IBOutlet weak var allowDSSSwitch: UISwitch!
    @IBOutlet weak var allowOfflineUseSwitch: UISwitch!
    @IBOutlet weak var defaultNetworkTimeoutMSTextField: UITextField!
    @IBOutlet weak var configNameTextField: UITextField!

    var settings : AylaSystemSettings!
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        settings = AylaNetworks.shared().systemSettings.aura_copy()
        self.appIdTextField.text = settings.appId
        self.appSecretTextField.text = settings.appSecret
        self.serviceTypePicker.selectRow(Int(settings.serviceType.rawValue), inComponent: 0, animated: true)
        self.serviceLocationPicker.selectRow(Int(settings.serviceLocation.rawValue), inComponent: 0, animated: true)
        self.allowDSSSwitch.on = settings.allowDSS
        self.allowOfflineUseSwitch.on = settings.allowOfflineUse
        self.defaultNetworkTimeoutMSTextField.text = String(settings.defaultNetworkTimeout)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendConfig(sender: AnyObject) {
        guard appIdTextField.text?.characters.count > 0
            else {
                UIAlertController.alert("Error", message: "AppID is required", buttonTitle: "OK", fromController: self)
                return
        }
        let appId = appIdTextField.text!
        
        guard appSecretTextField.text?.characters.count > 0
            else {
                UIAlertController.alert("Error", message: "AppSecret is required", buttonTitle: "OK", fromController: self)
                return
        }
        let appSecret = appSecretTextField.text!
        
        guard defaultNetworkTimeoutMSTextField.text?.characters.count > 0
            else {
                UIAlertController.alert("Error", message: "defaultNetworkTimeout is required", buttonTitle: "OK", fromController: self)
                return
        }
        guard let defaultNetworkTimeout = NSTimeInterval(defaultNetworkTimeoutMSTextField.text!)
            else {
                UIAlertController.alert("Error", message: "defaultNetworkTimeout is invalid", buttonTitle: "OK", fromController: self)
                return
        }
        
        guard configNameTextField.text?.characters.count > 0
            else {
                UIAlertController.alert("Error", message: "Config name is required", buttonTitle: "OK", fromController: self)
                return
        }
        let configName = configNameTextField.text!
        
        do {
            
            settings.appId = appId
            settings.appSecret = appSecret
            settings.serviceType = AylaServiceType(rawValue:UInt16(self.serviceTypePicker.selectedRowInComponent(0)))!
            settings.serviceLocation = AylaServiceLocation(rawValue:UInt16(self.serviceLocationPicker.selectedRowInComponent(0)))!
            settings.allowDSS = self.allowDSSSwitch.on
            settings.allowOfflineUse = self.allowOfflineUseSwitch.on
            settings.defaultNetworkTimeout = defaultNetworkTimeout
            
            guard let configData = try AuraConfig.createConfig(configName, fromSettings: settings, devices: nil)
                else {
                    UIAlertController.alert("Error", message: "Invalid settings, could not create config file", buttonTitle: "OK", fromController: self)
                    return
            }
            let configText = String(data: configData, encoding: NSUTF8StringEncoding)
            print(configText!)
        } catch _ {
            UIAlertController.alert("Error", message: "Invalid settings, could not create config file", buttonTitle: "OK", fromController: self)
        }
        
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == self.serviceTypePicker {
            return 4
        }
        if pickerView == self.serviceLocationPicker {
            return 3
        }
        return 0
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == self.serviceTypePicker {
            guard let serviceTypeName = AylaServiceType(rawValue: UInt16(row))?.name()
                else {
                    return nil
            }
            return serviceTypeName
        }
        if pickerView == self.serviceLocationPicker {
            guard let serviceLocationName = AylaServiceLocation(rawValue: UInt16(row))?.name()
                else {
                    return nil
            }
            return serviceLocationName
        }
        return nil
    }
}
