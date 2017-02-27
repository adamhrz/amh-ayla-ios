//
//  GrillRightDevice.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 12/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import Ayla_LocalDevice_SDK

class GrillRightDevice: AylaBLEDevice {
    static let timeFormat = "%02d:%02d:%02d"
    enum ControlMode: Int {
        case None = 0
        case Meat
        case Temp
        case Time
        static func name(mode: ControlMode) -> String {
            switch mode {
            case None:
                return "None"
            case Meat:
                return "Meat Profile"
            case Temp:
                return "Temperature"
            case Time:
                return "Cook Timer"
            }
        }
        var name: String {
            get {
                return ControlMode.name(self)
            }
        }
        
        static let caseCount = ControlMode.Time.rawValue + 1
        
    }
    
    enum MeatType: Int {
        case None = 0
        case Beef
        case Veal
        case Lamb
        case Pork
        case Chicken
        case Turkey
        case Fish
        case Hamburger
        static func name(type: MeatType) -> String {
            switch type {
            case None:
                return "None"
            case Beef:
                return "Beef"
            case Veal:
                return "Veal"
            case Lamb:
                return "Lamb"
            case Pork:
                return "Pork"
            case Chicken:
                return "Chicken"
            case Turkey:
                return "Turkey"
            case Fish:
                return "Fish"
            case Hamburger:
                return "Hamburger"
            }
        }
        var name: String {
            get {
                return MeatType.name(self)
            }
        }
        
        static let caseCount = MeatType.Hamburger.rawValue + 1
    }
    
    enum Doneness: Int {
        case None = 0
        case Rare
        case MediumRare
        case Medium
        case MediumWell
        case WellDone
        static func name(doneness: Doneness) -> String {
            switch doneness {
            case None:
                return "None"
            case Rare:
                return "Rare"
            case MediumRare:
                return "Medium Rare"
            case Medium:
                return "Medium"
            case MediumWell:
                return "Medium Well"
            case WellDone:
                return "Well Done"
            }
        }
        var name: String {
            get {
                return Doneness.name(self);
            }
        }
        
        static let caseCount = Doneness.WellDone.rawValue + 1
    }
    
    enum AlarmState: Int {
        case None = 0
        case AlmostDone
        case Overdone
        
        static func name(state: AlarmState) -> String {
            switch state {
            case .None:
                return "None"
            case .AlmostDone:
                return "Almost Done"
            case .Overdone:
                return "Overdone"
            }
        }
        var name: String {
            get {
                return AlarmState.name(self);
            }
        }
        
        static let caseCount = AlarmState.Overdone.rawValue + 1
    }
    
    class Sensor: NSObject {
        init(device: GrillRightDevice, index: Int) {
            self.device = device
            self.index = index
        }
        var index: Int
        weak var device: GrillRightDevice!
        
        var currentTemp: Int? {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TEMP : GrillRightDevice.PROP_SENSOR2_TEMP)
                return device.valueForProperty(property as! AylaLocalProperty) as? Int
            }
        }
        
        var alarmState: AlarmState {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_ALARM : GrillRightDevice.PROP_SENSOR2_ALARM) as! AylaLocalProperty
                let value = device.valueForProperty(property)
                guard let intValue = value as? Int, let state = AlarmState(rawValue: intValue) else {
                    return AlarmState.None
                }
                return state
            }
        }
        
        var meatType: MeatType {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_MEAT : GrillRightDevice.PROP_SENSOR2_MEAT) as! AylaLocalProperty
                let value = device.valueForProperty(property)
                guard let intValue = value as? Int, let meatType = MeatType(rawValue: intValue) else {
                    return MeatType.None
                }
                return meatType
            }
        }
        var doneness: Doneness {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_DONENESS : GrillRightDevice.PROP_SENSOR2_DONENESS)  as! AylaLocalProperty
                let value = device.valueForProperty(property)
                
                guard let intValue = value as? Int else {
                    return Doneness.None
                }
                guard let doneness = Doneness(rawValue: Int(intValue)) else {
                    return Doneness.None
                }
                return doneness
            }
        }
        var controlMode: ControlMode {
            get {
                
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_CONTROL_MODE : GrillRightDevice.PROP_SENSOR2_CONTROL_MODE)  as! AylaLocalProperty
                guard let intValue =  device.valueForProperty(property) as? Int, let mode = ControlMode(rawValue: intValue) else {
                    return ControlMode.None
                }
                return mode
            }
        }
        var isCooking: Bool {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_COOKING : GrillRightDevice.PROP_SENSOR2_COOKING)
                guard let isCooking = device.valueForProperty(property as! AylaLocalProperty) as? Bool else {
                    return false
                }
                return isCooking
            }
        }
        var targetTime: String {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TIME : GrillRightDevice.PROP_SENSOR2_TARGET_TIME)
                return device.valueForProperty(property as! AylaLocalProperty) as! String
            }
        }
        var currentTime: String {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TIME : GrillRightDevice.PROP_SENSOR2_TIME)
                return device.valueForProperty(property as! AylaLocalProperty) as! String
            }
        }
        var currentHours:Int? {
            get {
                let components = self.currentTime.componentsSeparatedByString(":")
                if components.count != 3 {
                    return 0
                }
                return Int(components[0])
            }
        }
        
        var currentMinutes:Int? {
            get {
                let components = self.currentTime.componentsSeparatedByString(":")
                if components.count != 3 {
                    return 0
                }
                return Int(components[1])
            }
        }
        
        var currentSeconds:Int? {
            get {
                let components = self.currentTime.componentsSeparatedByString(":")
                if components.count != 3 {
                    return 0
                }
                return Int(components[2])
            }
        }
        var targetTemp: Int {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TEMP : GrillRightDevice.PROP_SENSOR2_TARGET_TEMP)
                return device.valueForProperty(property as! AylaLocalProperty) as! Int
            }
        }
        var pctDone: Int {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_PCT_DONE : GrillRightDevice.PROP_SENSOR2_PCT_DONE)
                guard let pctDone = device.valueForProperty(property as! AylaLocalProperty) as? Int else {
                    return 0
                }
                return pctDone
            }
        }
    }
    
    var channel1: Sensor {
        get {
            return Sensor(device: self, index: 1)
        }
    }
    
    var channel2: Sensor {
        get {
            return Sensor(device: self, index: 2)
        }
    }
    
    private class InternalSensor: NSObject {
        init (sensor: InternalSensor) {
            super.init()
            self.device = sensor.device
            self.index = sensor.index
            self.name = sensor.name
            self.currentValue = sensor.currentValue
            self.currentTemp = sensor.currentTemp
            self.meatType = sensor.meatType
            self.doneness = sensor.doneness
            self.controlMode = sensor.controlMode
            self.targetTime = sensor.targetTime
            self.targetHours = sensor.targetHours
            self.targetMinutes = sensor.targetMinutes
            self.targetSeconds = sensor.targetSeconds
            self.currentHours = sensor.currentHours
            self.currentMinutes = sensor.currentMinutes
            self.currentSeconds = sensor.currentSeconds
            self.targetTemp = sensor.targetTemp
            self.pctDone = sensor.pctDone
            self.name = sensor.name
            self.cooking = sensor.cooking
            self.alarmState = sensor.alarmState
            
        }
        override init () {
            super.init()
        }
        weak var device: GrillRightDevice!
        var currentValue: NSData!
        
        var currentTemp: Int?
        var alarmState = AlarmState.None
        var meatType = MeatType.None
        var doneness = Doneness.None
        var controlMode = ControlMode.None
        
        var isCooking : Bool {
            get {
                return cooking == 1
            }
        }
        
        var targetTime: String {
            get {
                return String(format: GrillRightDevice.timeFormat, self.targetHours ?? 0, self.targetMinutes ?? 0, self.targetSeconds ?? 0)
            }
            set {
                let components = newValue.componentsSeparatedByString(":")
                if components.count != 3 {
                    return
                }
                self.targetHours = Int(components[0])
                self.targetMinutes = Int(components[1])
                self.targetSeconds = Int(components[2])
            }
        }
        var targetHours: Int?
        var targetMinutes: Int?
        var targetSeconds: Int?
        
        // Current timer values
        var currentTime: String {
            get {
                return String(format: GrillRightDevice.timeFormat, self.currentHours ?? 0, self.currentMinutes ?? 0, self.currentSeconds ?? 0)
            }
        }
        
        var currentHours: Int?
        var currentMinutes: Int?
        var currentSeconds: Int?
        
        var targetTemp = 0
        var pctDone = 0
        var name: String?
        var index: Int!
        var cooking: Int?
        
        func updateProperty(propertyName: String, withValue value:AnyObject) -> AylaPropertyChange? {
            let newDatapoint = AylaDatapoint(value: value)
            newDatapoint.dataSource = .Cloud
            newDatapoint.createdAt = NSDate()
            newDatapoint.updatedAt = newDatapoint.createdAt
            let property = device.getProperty(propertyName) as? AylaLocalProperty
            property?.originalProperty.datapoint = newDatapoint
            let change = property?.updateFromDatapoint(newDatapoint)
            print("Updated property \(property?.name) with value:\(value), updated value \(property?.value), original property value: \(property?.originalProperty.value)")
            if let property = property {
                property.pushUpdateToCloudWithSuccess(nil, failure: nil)
            }
            
            return change
        }
        
        func update(fromData data: NSData) -> [AylaChange]? {
            var changes = [AylaChange]()
            
            //Current temperature
            var temp16: UInt16 = 0
            data.getBytes(&temp16, range: NSRange(location: 12, length: 2))
            var temp = -1
            if temp16 != 0x8FFF { //0x8FFF = no sensor
                temp = Int(temp16)
            }
            
            if currentTemp == nil || temp != currentTemp! {
                self.currentTemp = temp
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TEMP : GrillRightDevice.PROP_SENSOR2_TEMP, withValue: temp) {
                    changes.append(change)
                }
            }
            print("Current temperature: \(currentTemp)")
            
            //isCooking
            var isCookingByte: Int8 = 0
            data.getBytes(&isCookingByte, range: NSRange(location: 0, length: 1))
            isCookingByte = isCookingByte & 0x0F
            
            let alarmState = isCookingByte == 0x0B ? AlarmState.AlmostDone : isCookingByte == 0x0F ? AlarmState.Overdone : AlarmState.None
            if alarmState != self.alarmState {
                self.alarmState = alarmState
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_ALARM : GrillRightDevice.PROP_SENSOR2_ALARM, withValue: alarmState.rawValue) {
                    changes.append(change)
                }
            }
            
            var isCooking = isCookingByte & 0x04 == 0x04 ? 1 : 0
            if alarmState != .None {
                isCooking = 1
            }
            if self.cooking == nil || isCooking != self.cooking! {
                self.cooking = isCooking
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_COOKING : GrillRightDevice.PROP_SENSOR2_COOKING, withValue: isCooking) {
                    changes.append(change)
                }
            }
            
            //Control Mode
            var controlModeByte: Int8 = 0
            data.getBytes(&controlModeByte, range: NSRange(location: 0, length: 1))
            controlModeByte = controlModeByte & 0x03
            let controlMode = ControlMode(rawValue: Int(controlModeByte))
            if controlMode != self.controlMode {
                self.controlMode = controlMode!
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_CONTROL_MODE : GrillRightDevice.PROP_SENSOR2_CONTROL_MODE, withValue: controlMode!.rawValue) {
                    changes.append(change)
                }
            }
            
            //target temperature
            var targetTemp16: UInt16 = 0
            data.getBytes(&targetTemp16, range: NSRange(location: 10, length: 2))
            var targetTemp = -1
            if targetTemp16 != 0x8FFF { //0x8FFF = no sensor
                targetTemp = Int(targetTemp16)
            }
            if self.targetTemp != targetTemp {
                self.targetTemp = targetTemp
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TEMP : GrillRightDevice.PROP_SENSOR2_TARGET_TEMP, withValue: targetTemp) {
                    changes.append(change)
                }
            }
            
            //Meat Type
            var meatByte: Int8 = 0
            data.getBytes(&meatByte, range: NSRange(location: 1, length: 1))
            let meat = MeatType(rawValue: Int(meatByte))
            if meat != nil && meat != self.meatType {
                self.meatType = meat!
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_MEAT : GrillRightDevice.PROP_SENSOR2_MEAT, withValue: meat!.rawValue) {
                    changes.append(change)
                }
            }
            
            //Doneness
            var donenessByte: Int8 = 0
            data.getBytes(&donenessByte, range: NSRange(location: 2, length: 1))
            let doneness = Doneness(rawValue: Int(donenessByte))
            if doneness != nil && doneness != self.doneness {
                self.doneness = doneness!
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_DONENESS : GrillRightDevice.PROP_SENSOR2_DONENESS, withValue: doneness!.rawValue) {
                    changes.append(change)
                }
            }
            
            var timeChanged = false
            var targetHours = 0
            data.getBytes(&targetHours, range: NSRange(location: 3, length: 1))
            if self.targetHours == nil || targetHours != self.targetHours {
                self.targetHours = targetHours
                timeChanged = true
            }
            var targetMinutes = 0
            data.getBytes(&targetMinutes, range: NSRange(location: 4, length: 1))
            if self.targetMinutes == nil || targetMinutes != self.targetMinutes {
                self.targetMinutes = targetMinutes
                timeChanged = true
            }
            var targetSeconds = 0
            data.getBytes(&targetSeconds, range: NSRange(location: 5, length: 1))
            if self.targetSeconds == nil || targetSeconds != self.targetSeconds {
                self.targetSeconds = targetSeconds
                timeChanged = true
            }
            if timeChanged {
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TIME : GrillRightDevice.PROP_SENSOR2_TARGET_TIME, withValue: self.targetTime) {
                    changes.append(change)
                }
            }
            
            timeChanged = false
            var currentHours = 0
            data.getBytes(&currentHours, range: NSRange(location: 6, length: 1))
            if self.currentHours == nil || currentHours != self.currentHours {
                self.currentHours = currentHours
                timeChanged = true
            }
            var currentMinutes = 0
            data.getBytes(&currentMinutes, range: NSRange(location: 7, length: 1))
            if self.currentMinutes == nil || currentMinutes != self.currentMinutes {
                self.currentMinutes = currentMinutes
                timeChanged = true
            }
            var currentSeconds = 0
            data.getBytes(&currentSeconds, range: NSRange(location: 8, length: 1))
            if self.currentSeconds == nil || currentSeconds != self.currentSeconds {
                self.currentSeconds = currentSeconds
                timeChanged = true
            }
            if timeChanged {
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TIME : GrillRightDevice.PROP_SENSOR2_TIME, withValue: self.currentTime) {
                    changes.append(change)
                }
            }
            
            //Percentage Done
            var pctDone16: UInt16 = 0
            data.getBytes(&pctDone16, range: NSRange(location: 14, length: 2))
            let pctDone = Int(pctDone16)
            if self.pctDone != pctDone {
                self.pctDone = pctDone
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_PCT_DONE : GrillRightDevice.PROP_SENSOR2_PCT_DONE, withValue: pctDone) {
                    changes.append(change)
                }
            }
            
            self.currentValue = data
            return changes.count > 0 ? changes : nil
        }
    }
    
    class Command: NSObject {
        static func startCookingCommand(index: Int, mode: ControlMode) -> NSMutableData {
            return NSMutableData(bytes: [UInt8(0x83), UInt8(index), UInt8(mode.rawValue)], length: 3)
        }
        static func stopCookingCommand(index: Int) -> NSMutableData {
            return NSMutableData(bytes: [UInt8(0x84), UInt8(index), UInt8(0x00)], length: 3)
        }
        private static func setFields(sensor: InternalSensor) -> NSMutableData {
            var command = [UInt8](count:13, repeatedValue: 0)
            command[0] = UInt8(0x82)
            command[1] = UInt8(sensor.index)
            command[2] = UInt8(sensor.meatType.rawValue)
            command[3] = UInt8(sensor.doneness.rawValue)
            command[4] = UInt8(sensor.targetTemp & 0xFF)
            command[5] = UInt8((UInt16(sensor.targetTemp) & 0xFF00) >> 8)
            command[6] = UInt8(sensor.targetHours!)
            command[7] = UInt8(sensor.targetMinutes!)
            command[8] = UInt8(sensor.targetSeconds!)
            command[9] = UInt8(sensor.targetHours!)
            command[10] = UInt8(sensor.targetMinutes!)
            command[11] = UInt8(sensor.targetSeconds!)
            
            return NSMutableData(bytes: command, length: command.count)
        }
    }
    
    private lazy var sensor1: InternalSensor = {
        [unowned self] in
        let sensor = InternalSensor()
        sensor.device = self
        sensor.index = 1
        return sensor
        }()
    
    private lazy var sensor2: InternalSensor = {
        [unowned self] in
        let sensor = InternalSensor()
        sensor.device = self
        sensor.index = 2
        return sensor
        }()
    
    static let GRILL_RIGHT_MODEL:String = "GrillRight"
    static let GRILL_RIGHT_OEM:String = "OreSci"
    static let GRILL_RIGHT_OEM_MODEL:String = "GrillRight"
    static let GRILL_RIGHT_DEFAULT_NAME:String = "GrillRight Thermometer"
    static let SERVICE_GRILL_RIGHT:String = "2899FE00-C277-48A8-91CB-B29AB0F01AC4"
    
    // GrillRight custom UUIDs
    static let CHARACTERISTIC_ID_CONTROL = CBUUID(string: "28998E03-C277-48A8-91CB-B29AB0F01AC4");
    
    static let CHARACTERISTIC_ID_SENSOR1 = CBUUID(string: "28998E10-C277-48A8-91CB-B29AB0F01AC4");
    
    static let CHARACTERISTIC_ID_SENSOR2 = CBUUID(string: "28998E11-C277-48A8-91CB-B29AB0F01AC4");
    
    // Battery Service UUIDs
    static let SERVICE_BATTERY = CBUUID(string: "0000180F-0000-1000-8000-00805f9b34fb");
    
    static let CHARACTERISTIC_ID_BATTERY_LEVEL = CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb");
    
    // Property names
    static let PROP_SENSOR1_TEMP:String = "00:grillrt:TEMP"
    static let PROP_SENSOR2_TEMP:String = "01:grillrt:TEMP"
    static let PROP_SENSOR1_MEAT:String = "00:grillrt:MEAT"
    static let PROP_SENSOR2_MEAT:String = "01:grillrt:MEAT"
    static let PROP_SENSOR1_DONENESS:String = "00:grillrt:DONENESS"
    static let PROP_SENSOR2_DONENESS:String = "01:grillrt:DONENESS"
    static let PROP_SENSOR1_TARGET_TEMP:String = "00:grillrt:TARGET_TEMP"
    static let PROP_SENSOR2_TARGET_TEMP:String = "01:grillrt:TARGET_TEMP"
    static let PROP_SENSOR1_PCT_DONE:String = "00:grillrt:PCT_DONE"
    static let PROP_SENSOR2_PCT_DONE:String = "01:grillrt:PCT_DONE"
    static let PROP_SENSOR1_COOKING:String = "00:grillrt:COOKING"
    static let PROP_SENSOR2_COOKING:String = "01:grillrt:COOKING"
    static let PROP_SENSOR1_TARGET_TIME:String = "00:grillrt:TARGET_TIME"
    static let PROP_SENSOR2_TARGET_TIME:String = "01:grillrt:TARGET_TIME"
    static let PROP_SENSOR1_TIME:String = "00:grillrt:TIME"
    static let PROP_SENSOR2_TIME:String = "01:grillrt:TIME"
    static let PROP_SENSOR1_CONTROL_MODE:String = "00:grillrt:CONTROL_MODE"
    static let PROP_SENSOR2_CONTROL_MODE:String = "01:grillrt:CONTROL_MODE"
    static let PROP_SENSOR1_ALARM:String = "00:grillrt:ALARM"
    static let PROP_SENSOR2_ALARM:String = "01:grillrt:ALARM"
    
    override var oemModel: String? {
        get {
            return super.oemModel ?? GrillRightDevice.GRILL_RIGHT_OEM_MODEL
        }
        set {
            super.oemModel = newValue
        }
    }
    
    override var model: String? {
        get {
            return super.model ?? GrillRightDevice.GRILL_RIGHT_MODEL
        }
        set {
            super.model = newValue
        }
    }
    override var productName: String? {
        get {
            return super.productName ?? GrillRightDevice.GRILL_RIGHT_DEFAULT_NAME
        }
        set {
            super.productName = newValue
        }
    }
    
    override var isConnectedLocal: Bool {
        get {
            return peripheral.state == .Connected
        }
    }
    
    override func characteristicsToFetch() -> [CBUUID]? {
        return nil
    }
    
    var controlCharacteristic: CBCharacteristic?
    override func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for characteristic in service.characteristics! {
            switch characteristic.UUID {
            case GrillRightDevice.CHARACTERISTIC_ID_CONTROL:
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                controlCharacteristic = characteristic
            case GrillRightDevice.CHARACTERISTIC_ID_SENSOR1:
                fallthrough
            case GrillRightDevice.CHARACTERISTIC_ID_SENSOR2:
                peripheral.readValueForCharacteristic(characteristic)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            default:
                break;
            }
        }
    }
    
    override func servicesToDiscover() -> [CBUUID] {
        return [CBUUID(string: GrillRightDevice.SERVICE_GRILL_RIGHT)]
    }
    
    override func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Updated characteristic value: \(characteristic)")
        guard  let value = characteristic.value else {
            print("Characteristic contais no value")
            return
        }
        var changes: [AylaChange]?
        switch characteristic.UUID {
        case GrillRightDevice.CHARACTERISTIC_ID_SENSOR1:
            changes = sensor1.update(fromData: value)
        case GrillRightDevice.CHARACTERISTIC_ID_SENSOR2:
            changes = sensor2.update(fromData: value)
        default:
            break
        }
        if let changes = changes {
            self.notifyChangesToListeners(changes)
        }
    }
    override func valueForProperty(property: AylaLocalProperty) -> AnyObject? {
        if !isConnectedLocal {
            return property.originalProperty.value
        }
        switch property.name {
        case GrillRightDevice.PROP_SENSOR1_TEMP:
            return sensor1.currentTemp ?? 0
        case GrillRightDevice.PROP_SENSOR1_MEAT:
            return sensor1.meatType.rawValue
        case GrillRightDevice.PROP_SENSOR1_DONENESS:
            return sensor1.doneness.rawValue
        case GrillRightDevice.PROP_SENSOR1_TARGET_TEMP:
            return sensor1.targetTemp ?? 0
        case GrillRightDevice.PROP_SENSOR1_PCT_DONE:
            return sensor1.pctDone
        case GrillRightDevice.PROP_SENSOR1_COOKING:
            return sensor1.cooking ?? false
        case GrillRightDevice.PROP_SENSOR1_TARGET_TIME:
            return sensor1.targetTime
        case GrillRightDevice.PROP_SENSOR1_TIME:
            return sensor1.currentTime
        case GrillRightDevice.PROP_SENSOR1_CONTROL_MODE:
            return sensor1.controlMode.rawValue
        case GrillRightDevice.PROP_SENSOR1_ALARM:
            return sensor1.alarmState.rawValue
        case GrillRightDevice.PROP_SENSOR2_TEMP:
            return sensor2.currentTemp ?? 0
        case GrillRightDevice.PROP_SENSOR2_MEAT:
            return sensor2.meatType.rawValue
        case GrillRightDevice.PROP_SENSOR2_DONENESS:
            return sensor2.doneness.rawValue
        case GrillRightDevice.PROP_SENSOR2_TARGET_TEMP:
            return sensor2.targetTemp ?? 0
        case GrillRightDevice.PROP_SENSOR2_PCT_DONE:
            return sensor2.pctDone
        case GrillRightDevice.PROP_SENSOR2_COOKING:
            return sensor2.cooking ?? false
        case GrillRightDevice.PROP_SENSOR2_TARGET_TIME:
            return sensor2.targetTime
        case GrillRightDevice.PROP_SENSOR2_TIME:
            return sensor2.currentTime
        case GrillRightDevice.PROP_SENSOR2_CONTROL_MODE:
            return sensor2.controlMode.rawValue
        case GrillRightDevice.PROP_SENSOR2_ALARM:
            return sensor2.alarmState.rawValue
        default:
            return property.baseType.compare("string") == .OrderedSame ? "" : 0
        }
    }
    
    class WriteCommandDescriptor: NSObject {
        var update: (() -> ())
        var success: (() -> ())?
        var failure: ((NSError) -> ())?
        init(update: (() ->()), success: (() -> ())?, failure: ((NSError) -> ())?) {
            self.update = update
            self.success = success
            self.failure = failure
        }
    }
    private var writeCharacteristicDescriptors = [WriteCommandDescriptor]()
    
    override func setValue(value: AnyObject, forProperty property: AylaLocalProperty, success successBlock: (() -> Void)?, failure failureBlock: ((NSError) -> Void)?) -> AylaGenericTask? {
        guard let controlCharacteristic = controlCharacteristic else {
            if let failureBlock = failureBlock {
                failureBlock(AylaErrorUtils.errorWithDomain(AylaRequestErrorDomain, code: AylaRequestErrorCode.PreconditionFailure.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Control characteristic was not discovered", comment: "")]))
            }
            return nil
        }
        if !isConnectedLocal {
            if let failureBlock = failureBlock {
                failureBlock(AylaErrorUtils.errorWithDomain(AylaRequestErrorDomain, code: AylaRequestErrorCode.PreconditionFailure.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Properties are read-only unless the device is connected locally", comment: "")]))
            }
            return nil
        }
        var command = NSMutableData();
        var sensorCopy: InternalSensor
        var index: Int
        var sensor: InternalSensor
        var update: (() -> ())?
        if property.name.containsString("00:") {
            sensor = sensor1
            sensorCopy = InternalSensor(sensor: sensor1)
            index = 1
        } else {
            sensor = sensor2
            sensorCopy = InternalSensor(sensor: sensor2)
            index = 2
        }
        
        //cooking command has a different structure, so consider its case in a separate if instead of inside switch
        if  property.name.containsString("COOKING") {
            guard let mode = ControlMode(rawValue: value as! Int) else {
                return nil
            }
            if mode == .None {
                command = Command.stopCookingCommand(index)
            } else {
                command = Command.startCookingCommand(index, mode: mode)
            }
            update = {
                sensor.controlMode = mode
            }
        } else {
            switch property.name {
            case (let p) where p.containsString("MEAT"):
                guard let meatType = MeatType(rawValue: value as! Int) else {
                    return nil
                }
                sensorCopy.meatType = meatType
                update = {
                    sensor.meatType = meatType
                }
                
            case (let p) where p.containsString("DONENESS"):
                guard let doneness = Doneness(rawValue: value as! Int) else {
                    return nil
                }
                sensorCopy.doneness = doneness
                update = {
                    sensor.doneness = doneness
                }
                
            case (let p) where p.containsString("TARGET_TEMP"):
                guard let targetTemp = value as? Int else {
                    return nil
                }
                sensorCopy.targetTemp = targetTemp
                update = {
                    sensor.targetTemp = targetTemp
                }
                
            case (let p) where p.containsString("TARGET_TIME"):
                guard let targetTime = value as? String else {
                    return nil
                }
                sensorCopy.targetTime = targetTime
                update = {
                    sensor.targetTime = targetTime
                }
                
            default:
                print("Unknown property \(property.name)")
                return nil
            }
            command = Command.setFields(sensorCopy)
        }
        
        writeCharacteristicDescriptors.append(WriteCommandDescriptor(update: update!, success: successBlock, failure: failureBlock))
        let writeTask = AylaGenericTask(task: { () -> Bool in
            self.peripheral.writeValue(command, forCharacteristic: controlCharacteristic, type: CBCharacteristicWriteType.WithResponse)
            return true
            }, cancel: nil)
        dispatch_async(self.serialQueue) {
            writeTask.start()
        }
        return writeTask
    }
    override func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard let writeCharacteristicDescriptor = self.writeCharacteristicDescriptors.first else {
            return
        }
        self.writeCharacteristicDescriptors.removeFirst()
        if let error = error {
            if let failure = writeCharacteristicDescriptor.failure {
                failure(error)
            }
            return;
        }
        writeCharacteristicDescriptor.update()
        guard let success = writeCharacteristicDescriptor.success else { return }
        success();
    }
}
