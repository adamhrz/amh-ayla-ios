//
//  AuraConfigDeviceViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 9/6/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class AuraConfigDeviceViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var delegate : AuraConfigDeviceDelegate! = nil
    
    enum AuraConfigDeviceSection:Int {
        case Profile = 0
        case Properties
        case AddButton
    }
    @IBOutlet weak var dsnSwitch: UISwitch!
    @IBOutlet weak var dsnTextField: UITextField!
    @IBOutlet weak var modelSwitch: UISwitch!
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var oemModelSwitch: UISwitch!
    @IBOutlet weak var oemModelTextField: UITextField!
    
    var deviceManager : AylaDeviceManager? {
        get {
            let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
            return sessionManager?.deviceManager
        }
    }
    
    lazy var sortedDevices: [AylaDevice]? = {
        [unowned self] in
        if self.deviceManager == nil {
            return nil
        }
        var devices = [AylaDevice]()
        for (dsn, device) in self.deviceManager!.devices {
            devices.append(device as! AylaDevice)
        }
        devices.sortInPlace({ (device1, device2) -> Bool in
            device1.dsn < device2.dsn
        })
        return devices
    }()
    
    lazy var currentDevice : AylaDevice? = {
        [unowned self] in
        if self.sortedDevices?.count < 1 {
            return nil
        }
        
        return self.sortedDevices![0]
    }()
    
    lazy var currentDeviceProperties : [AylaProperty]? = {
        [unowned self] in
        return self.updateCurrentDeviceProperties()
    }()
    
    var selectedProperties = NSMutableArray()
    
    func updateCurrentDeviceProperties() -> [AylaProperty]? {
        if self.currentDevice?.properties?.count < 1 {
            return nil
        }
        var properties = [AylaProperty]()
        for (_, property) in self.currentDevice!.properties! {
            properties.append(property as! AylaProperty)
        }
        properties.sortInPlace({ (property1, property2) -> Bool in
            property1.name < property2.name
        })
        return properties
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelection = true
        guard let device = self.currentDevice
            else {
                print("Failed to initialize view")
                return
        }
        dsnTextField.text = device.dsn
        modelTextField.text = device.model
        oemModelTextField.text = device.oemModel
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if self.sortedDevices?.count < 1 {
                return 0
        }
        return sortedDevices!.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sortedDevices![row].productName
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let device = sortedDevices![row]
        dsnTextField.text = device.dsn
        modelTextField.text = device.model
        oemModelTextField.text = device.oemModel
        self.currentDevice = self.sortedDevices![row]
        self.currentDeviceProperties = updateCurrentDeviceProperties()
        selectedProperties = NSMutableArray()
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if AuraConfigDeviceSection(rawValue: section)! == .Properties {
            if currentDeviceProperties?.count < 1 {
                return 0
            }
            return currentDeviceProperties!.count
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
        if AuraConfigDeviceSection(rawValue: indexPath.section)! != .Properties {
            let staticCell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            staticCell.selectionStyle = .None
            return staticCell
        }
        let cellIdentifier = "PropertyCell"
        let propertyName = self.currentDeviceProperties![indexPath.row].name
        var propertyCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        if propertyCell == nil {
            propertyCell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.aylaHippieGreenColor()
            propertyCell?.selectedBackgroundView = backgroundView
        }
        
        propertyCell?.selected = selectedProperties.containsObject(propertyName)
        propertyCell?.textLabel?.text = propertyName
        
        return propertyCell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if AuraConfigDeviceSection(rawValue: indexPath.section)! != .Properties {
            return
        }
        let property = currentDeviceProperties![indexPath.row]
        selectedProperties.addObject(property.name)
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if AuraConfigDeviceSection(rawValue: indexPath.section)! != .Properties {
            return
        }
        let property = currentDeviceProperties![indexPath.row]
        selectedProperties.removeObject(property.name)
    }
    
    @IBAction func addToConfigAction(sender: AnyObject) {
        var deviceConfig = [String:AnyObject]()
        var attributeSelected = false
        if dsnSwitch.on {
            if dsnTextField.text?.characters.count < 1 {
                UIAlertController.alert("Error", message: "If DSN is enabled a valid DSN must be provided", buttonTitle: "OK", fromController: self)
                return
            }
            deviceConfig["dsn"] = dsnTextField!.text!
            attributeSelected = true
        }
        if modelSwitch.on {
            if modelTextField.text?.characters.count < 1 {
                UIAlertController.alert("Error", message: "If Model is enabled a valid model must be provided", buttonTitle: "OK", fromController: self)
                return
            }
            deviceConfig["model"] = modelTextField!.text!
            attributeSelected = true
        }
        if oemModelSwitch.on {
            if  oemModelTextField.text?.characters.count < 1 {
                UIAlertController.alert("Error", message: "If Model is enabled a valid model must be provided", buttonTitle: "OK", fromController: self)
                return
            }
            deviceConfig["oemModel"] = oemModelTextField!.text!
            attributeSelected = true
        }
        if !attributeSelected {
            UIAlertController.alert("Error", message: "Enable an attribute to identify the device", buttonTitle: "OK", fromController: self)
            return
        }
        if selectedProperties.count > 0 {
            deviceConfig["managedProperties"] = selectedProperties
        }
        
        delegate.deviceConfiguration(self, didFinishWithObject: deviceConfig)
    }
}

protocol AuraConfigDeviceDelegate {
    func deviceConfiguration(deviceConfiguration:AuraConfigDeviceViewController, didFinishWithObject deviceConfig:[String:AnyObject])
}