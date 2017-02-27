//
//  GrillRightSensorViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 12/29/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import ActionSheetPicker_3_0

class GrillRightSensorViewController: UIViewController {
    static let medGrayColor = UIColor(hexRGB: 0xc9c9c9)
    static let medGrayGreenColor = UIColor(hexRGB: 0xbfd190)
    static let medGrayYellowColor = UIColor(hexRGB: 0xede39a)
    static let medGrayAmberColor = UIColor(hexRGB: 0xead48c)
    static let medGrayOrangeColor = UIColor(hexRGB: 0xe2bc8a)
    static let medGrayRedColor = UIColor(hexRGB: 0xd8a997)
    
    static let medGreenColor = UIColor(hexRGB: 0x4b631f)
    static let medYellowColor = UIColor(hexRGB: 0xbaa401)
    static let medAmberColor = UIColor(hexRGB: 0xba8d00)
    static let medOrangeColor = UIColor(hexRGB: 0xce7604)
    static let medRedColor = UIColor(hexRGB: 0xa93e00)
    
    static let inactiveModeColor = UIColor(hexRGB: 0x535353)
    static let selectedModeColor = UIColor(hexRGB: 0x222222)
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var rightStatusLabel: UILabel!
    @IBOutlet weak var cookTimeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var switchButton: AuraProgressButton!
    
    @IBOutlet weak var cookTimeHeaderLabel: UILabel!
    @IBOutlet weak var rightStatusHeaderLabel: UILabel!
    
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var meatButton: UIButton!
    @IBOutlet weak var temperatureButton: UIButton!
    
    var sensor: GrillRightDevice.Sensor!
    var uiTimer: NSTimer!
    var currentTime: Int?
    var lastCurrentTimeUpdated = NSDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        refreshUI()
    }
    
    func refreshUI(change: AylaPropertyChange? = nil) {
        let runningBool = (sensor.isCooking || sensor.alarmState != .None)
        
        modeLabel.text = sensor.controlMode.name
        if let currentTemp = sensor.currentTemp {
            currentTempLabel.text = "\(Double(currentTemp)/10.0) F"
        }
        
        rightStatusHeaderLabel.text = ""
        rightStatusLabel.text = ""
        
        cookTimeLabel.text = ""
        cookTimeHeaderLabel.text = ""
        
        timerButton.imageView?.tintColor = GrillRightSensorViewController.inactiveModeColor
        meatButton.imageView?.tintColor = GrillRightSensorViewController.inactiveModeColor
        temperatureButton.imageView?.tintColor = GrillRightSensorViewController.inactiveModeColor
        
        if sensor.pctDone <= 100 {
            statusLabel.text = "\(sensor.pctDone)%"
        } else {
            
            statusLabel.text = ""
        }
        switchButton.enabled = true
        switch sensor.controlMode {
        case .Meat:
            cookTimeHeaderLabel.text = "Meat"
            cookTimeLabel.text = sensor.meatType.name
            rightStatusHeaderLabel.text = "Doneness"
            rightStatusLabel.text = sensor.doneness.name
            meatButton.imageView?.tintColor = GrillRightSensorViewController.selectedModeColor
            switchButton.enabled = !(sensor.meatType == .None || sensor.doneness == .None)
        case .Temp:
            rightStatusHeaderLabel.text = "Target Temperature"
            rightStatusLabel.text = "\(Double(sensor.targetTemp)/10.0)º F"
            temperatureButton.imageView?.tintColor = GrillRightSensorViewController.selectedModeColor
        case .Time:
            cookTimeHeaderLabel.text = "Set Cook Time"
            cookTimeLabel.text = sensor.targetTime
            rightStatusHeaderLabel.text = "Time Remaining"
            rightStatusLabel.text = runningBool ? sensor.currentTime : "--:--:--"
            if let change = change, lastPropertyUpdate = change.property.dataUpdatedAt {
                if change.property.name.containsString(":TIME") && lastPropertyUpdate.compare(lastCurrentTimeUpdated) == .OrderedDescending {
                    self.currentTime = sensor.currentHours! * 3600 + sensor.currentMinutes! * 60 + sensor.currentSeconds!
                    lastCurrentTimeUpdated = lastPropertyUpdate
                }
            }
            statusLabel.text = ""
            timerButton.imageView?.tintColor = GrillRightSensorViewController.selectedModeColor
        case .None:
            statusLabel.text = ""
        }
        switchButton.setTitle(runningBool ? "Stop" : "Start", forState: .Normal)
        switchButton.layer.backgroundColor = runningBool ? GrillRightSensorViewController.inactiveModeColor.CGColor : UIColor.aylaHippieGreenColor().CGColor

        
        var bgColor: UIColor
        var labelColor: UIColor
        switch sensor.alarmState {
        case .None:
            if sensor.isCooking {
                bgColor = GrillRightSensorViewController.medGrayGreenColor
                labelColor = UIColor.darkTextColor()
            } else {
                bgColor = GrillRightSensorViewController.medGrayColor
                labelColor = UIColor.darkGrayColor()
            }
        case .AlmostDone:
            bgColor = GrillRightSensorViewController.medGrayAmberColor
            labelColor = GrillRightSensorViewController.medAmberColor
        case .Overdone:
            bgColor = GrillRightSensorViewController.medGrayRedColor
            labelColor = GrillRightSensorViewController.medRedColor
        }
        
        self.view.backgroundColor = bgColor
        
        self.currentTempLabel.textColor = labelColor
        self.cookTimeLabel.textColor = labelColor
        self.rightStatusLabel.textColor = labelColor
        
        uiTimer?.invalidate()
        if runningBool {
            uiTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(refreshTimer), userInfo: nil, repeats:true)
        } else {
            currentTime = nil
        }
            
    }
    
    func refreshTimer() {
        if self.currentTime == nil {
            return
        }
        self.currentTime = self.currentTime! + (sensor.alarmState == .Overdone ? 1 : -1)
        let currentTime = self.currentTime!
        let seconds = currentTime % 60
        let minutes = (currentTime / 60) % 60
        let hours = (currentTime / 3600)
        rightStatusLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchAction(sender: AuraProgressButton) {
        sender.startActivityIndicator()
        self.uiTimer?.invalidate()
        self.uiTimer = nil
        writeValue(sensor.isCooking ? 0 : sensor.controlMode.rawValue, toProperty: sensor.index == 1 ? GrillRightDevice.PROP_SENSOR1_COOKING : GrillRightDevice.PROP_SENSOR2_COOKING, success: { (datapoint) in
            sender.stopActivityIndicator()
            self.refreshUI()
        }) { (error) in
            sender.stopActivityIndicator()
            error.displayAsAlertController()
            self.refreshUI()
        }

    }
    
    func writeValue(value: AnyObject, toProperty property:String, success successBlock: ((AylaDatapoint) -> Void)? = nil, failure failureBlock: ((NSError) -> Void)? = nil) {
        let device = sensor.device
        if let property = device.getProperty(property) {
            let parameters = AylaDatapointParams()
            
            
            parameters.value = value
            property.createDatapoint(parameters, success:{ (datapoint) in
                if let successBlock = successBlock {
                    successBlock(datapoint)
                }
                }, failure: { (error) in
                    print("Failed to create datapoint \(error)")
                if let failureBlock = failureBlock {
                    failureBlock(error)
                }
            })
        }

    }
    
    @IBAction func temperatureAction(sender: AnyObject) {
        if sensor.controlMode == .Temp && sensor.isCooking {
            return
        }
        let tempRange = [Int](100...572).map { String($0) }
        
        ActionSheetStringPicker.showPickerWithTitle("Select Target Temp.", rows: tempRange, initialSelection: 0, doneBlock: { (picker, index, value) in
            self.switchButton.startActivityIndicator()
            self.writeValue(Int(value as! String)! * 10, toProperty: self.sensor.index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TEMP : GrillRightDevice.PROP_SENSOR2_TARGET_TEMP)
            
            self.writeValue(GrillRightDevice.ControlMode.Temp.rawValue, toProperty: self.sensor.index == 1 ? GrillRightDevice.PROP_SENSOR1_COOKING : GrillRightDevice.PROP_SENSOR2_COOKING)
            }, cancelBlock: { (picker) in
                
            }, origin: sender)
    }

    @IBAction func meatAction(sender: AnyObject) {
        if sensor.controlMode == .Meat && sensor.isCooking {
            return
        }
        
        let meatArray = [Int](1...GrillRightDevice.MeatType.caseCount-1).map { GrillRightDevice.MeatType.name(GrillRightDevice.MeatType(rawValue: $0)!) }
        
        let donenessArray = [Int](1...GrillRightDevice.Doneness.caseCount-1).map { GrillRightDevice.Doneness.name(GrillRightDevice.Doneness(rawValue: $0)!) }
        
        ActionSheetMultipleStringPicker.showPickerWithTitle("Select Profile", rows: [meatArray, donenessArray], initialSelection: [0,0], doneBlock: { (picker, indexes, value) in
            self.switchButton.startActivityIndicator()
            self.writeValue((indexes as! [Int])[0] + 1, toProperty: self.sensor.index == 1 ? GrillRightDevice.PROP_SENSOR1_MEAT : GrillRightDevice.PROP_SENSOR2_MEAT, success:{ (datapoint) in
                self.switchButton.stopActivityIndicator()
                self.writeValue((indexes as! [Int])[1] + 1, toProperty: self.sensor.index == 1 ? GrillRightDevice.PROP_SENSOR1_DONENESS : GrillRightDevice.PROP_SENSOR2_DONENESS)
                
                self.writeValue(GrillRightDevice.ControlMode.Meat.rawValue, toProperty: self.sensor.index == 1 ? GrillRightDevice.PROP_SENSOR1_COOKING : GrillRightDevice.PROP_SENSOR2_COOKING)
                
                })
            }, cancelBlock: { (picker) in
                
            }, origin: sender)
    }
    
    @IBAction func timerAction(sender: AnyObject) {
        if sensor.controlMode == .Time && sensor.isCooking {
            return
        }
        let interval = NSTimeInterval(600)
        let date = NSDate(timeIntervalSinceReferenceDate:interval)
        ActionSheetDatePicker.showPickerWithTitle("Set Timer", datePickerMode: .CountDownTimer, selectedDate: date, doneBlock: { (picker, index, value) in
            self.switchButton.startActivityIndicator()
            let durationInSeconds = picker.countDownDuration
            let hours = Int(durationInSeconds / 3600)
            let minutes = Int((durationInSeconds / 60) % 60)
            let seconds = Int(durationInSeconds % 60)
            var propValue = "\(hours):\(minutes):\(seconds)"
            if propValue == "0:0:0" {
                propValue = "0:1:0"  // Special case for bug in UIDatePicker
            }
            print("Timer String:%@", propValue)
            self.writeValue(propValue, toProperty: self.sensor.index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TIME : GrillRightDevice.PROP_SENSOR2_TARGET_TIME)
            
            self.writeValue(GrillRightDevice.ControlMode.Time.rawValue, toProperty: self.sensor.index == 1 ? GrillRightDevice.PROP_SENSOR1_COOKING : GrillRightDevice.PROP_SENSOR2_COOKING, success: { (datapoint) in
                self.switchButton.stopActivityIndicator()
                }, failure: { (error) in
                    error.displayAsAlertController()
            })
            }, cancelBlock: { (picker) in
                
            }, origin: self.view)

    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
