//
//  AuraConfigViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 9/2/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import MessageUI

class AuraConfigViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, AuraConfigDeviceDelegate, MFMailComposeViewControllerDelegate {
    enum Section:Int {
        case Settings = 0
        case Devices
        case Send
    }
    @IBOutlet weak var appIdTextField: UITextField!
    @IBOutlet weak var appSecretTextField: UITextField!
    @IBOutlet weak var serviceTypePicker: UIPickerView!
    @IBOutlet weak var serviceLocationPicker: UIPickerView!
    @IBOutlet weak var allowDSSSwitch: UISwitch!
    @IBOutlet weak var allowOfflineUseSwitch: UISwitch!
    @IBOutlet weak var defaultNetworkTimeoutMSTextField: UITextField!
    @IBOutlet weak var configNameTextField: UITextField!

    var settings : AylaSystemSettings!
    var deviceConfigurations = [[String:AnyObject]]()
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
            
            
            guard let configData = try AuraConfig.createConfig(configName, fromSettings: settings, devices: deviceConfigurations)
                else {
                    UIAlertController.alert("Error", message: "Invalid settings, could not create config file", buttonTitle: "OK", fromController: self)
                    return
            }
            let configText = String(data: configData, encoding: NSUTF8StringEncoding)
            print(configText!)
            showMailComposer(configName, configData: configData)
        } catch _ {
            UIAlertController.alert("Error", message: "Invalid settings, could not create config file", buttonTitle: "OK", fromController: self)
        }
        
    }
    
    func showMailComposer(configName: String, configData: NSData) {
        let mailVC = MFMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            mailVC.setSubject("Aura Configuration file")
            
            let configText = String(data: configData, encoding: NSUTF8StringEncoding)
            let emailMessageBody = "Open the attached configuration file to apply it to Aura App. Preview:\n\(configText!)"
            mailVC.setMessageBody(emailMessageBody, isHTML: false)
            mailVC.addAttachmentData(configData, mimeType: "application/text", fileName: "\(configName).auraconfig")
            mailVC.mailComposeDelegate = self
            
            presentViewController(mailVC, animated: true, completion: nil)
        }
        else  {
            UIAlertController.alert(nil, message: "Unable to send an email.", buttonTitle: "Got it", fromController: self)
        }
    }
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
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
    
    override func tableView(tableView: UITableView, titleForFooterInSection sectionNumber: Int) -> String? {
        guard let section = Section(rawValue: sectionNumber)
            else {
                return nil
        }
        if section != .Devices {
            return nil
        }
        
        if deviceConfigurations.count < 1 {
                return "No device configurations added"
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Section(rawValue: section)! == .Devices {
            if deviceConfigurations.count < 1 {
                return 0
            }
            return deviceConfigurations.count
        }
        
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if Section(rawValue: indexPath.section)! != .Devices {
            let staticCell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            return staticCell
        }
        let cellIdentifier = "DeviceConfCell"
        var configuration = self.deviceConfigurations[indexPath.row]
        var propertyCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        if propertyCell == nil {
            propertyCell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
            propertyCell?.textLabel?.minimumScaleFactor = 0.6
            propertyCell?.textLabel?.adjustsFontSizeToFitWidth = true
            propertyCell?.detailTextLabel?.minimumScaleFactor = 0.8
            propertyCell?.detailTextLabel?.adjustsFontSizeToFitWidth = true
        }
        
        if let managedProperties = configuration["managedProperties"] as? [String] {
            propertyCell?.detailTextLabel?.text = managedProperties.description
            configuration.removeValueForKey("managedProperties")
        }
        
        propertyCell?.textLabel?.text = configuration.description
        
        return propertyCell!
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if Section(rawValue: indexPath.section)! == .Devices {
            return .Delete
        }
        return .None
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        deviceConfigurations.removeAtIndex(indexPath.row)
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let configDeviceViewController = segue.destinationViewController as? AuraConfigDeviceViewController
            else {
                return
        }
        configDeviceViewController.delegate = self
    }
    
    func deviceConfiguration(deviceConfiguration: AuraConfigDeviceViewController, didFinishWithObject deviceConfig: [String : AnyObject]) {
        deviceConfigurations.append(deviceConfig)
        deviceConfiguration.navigationController?.popViewControllerAnimated(true)
        tableView.reloadData()
    }
}
