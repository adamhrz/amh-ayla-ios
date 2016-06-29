//
//  ScheduleEditorTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 5/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class ScheduleEditorTableViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var onDatePicker: UIDatePicker!
    @IBOutlet weak var offDatePicker: UIDatePicker!
    @IBOutlet weak var onTimeDatePicker: UIDatePicker!
    @IBOutlet weak var offTimeDatePicker: UIDatePicker!
    @IBOutlet weak var repeatPicker: UIPickerView!
    @IBOutlet weak var saveScheduleButton: AuraButton!
    @IBOutlet weak var utcSwitch: UISwitch!
    @IBOutlet weak var actionPicker: UIPickerView!
    
    var dateFormatter : NSDateFormatter!
    var timeFormatter : NSDateFormatter!
    var timeZone : NSTimeZone!
    
    var atStartAction : AylaScheduleAction?
    var atEndAction : AylaScheduleAction?
    
    enum RepeatType: Int {
        case None
        case Daily
        case Weekends
        case Weekdays
        static let count : Int = {
            var count = 0
            while let _ = RepeatType(rawValue: count) { count += 1 }
            return count
        }()
    }
    
    enum ActionType: Int {
        case TurnOnOff
        case TurnOffOn
        case TurnOn
        case TurnOff
        
        static let count : Int = {
            var count = 0
            while let _ = RepeatType(rawValue: count) { count += 1 }
            return count
        }()
        
        func description() -> String {
            switch self {
            case .TurnOff:
                return "Turn Off"
            case .TurnOffOn:
                return "Turn Off/On"
            case .TurnOn:
                return "Turn On"
            case .TurnOnOff:
                return "Turn On/Off"
            }
        }
    }
    
    var repeatType = RepeatType.None
    var actionType = ActionType.TurnOnOff
    
    var schedule : AylaSchedule! = nil {
        didSet {
            timeZone = schedule.utc ? NSTimeZone(forSecondsFromGMT: 0) : NSTimeZone.localTimeZone()
            
            dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = timeZone
            
            timeFormatter = NSDateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            timeFormatter.timeZone = timeZone

            schedule.fetchAllScheduleActionsWithSuccess({ (actions) in
                if actions.count != 2 {
                    print("Found more or less than 2 actions, schedule will not work properly")
                    return
                }
                
                if actions.first?.firePoint == .AtStart {
                    self.atStartAction = actions.first
                    self.atEndAction = actions.last
                } else {
                    self.atStartAction = actions.last
                    self.atEndAction = actions.first
                }
                self.actionType = ActionType(rawValue: 0)!
                if self.atStartAction!.active {
                    if self.atEndAction!.active {
                        if self.atStartAction!.value as! Int == 1 {
                            self.actionType = .TurnOnOff
                        } else {
                            self.actionType = .TurnOffOn
                        }
                    } else {
                        if self.atStartAction!.value as! Int == 1 {
                            self.actionType = .TurnOn
                        } else {
                            self.actionType = .TurnOff
                        }
                        
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                    }
                    self.actionPicker.selectRow(self.actionType.rawValue, inComponent: 0, animated: true)
                }
                }) { (error) in
                    print(error.userInfo)
            }
        }
    }
    
    var device : AylaDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }
    
    func updateUI() {
        onDatePicker.date = dateFormatter.dateFromString(schedule.startDate ?? "") ?? NSDate()
        onTimeDatePicker.date = timeFormatter.dateFromString(schedule.startTimeEachDay ?? "") ?? NSDate()
        offDatePicker.date = dateFormatter.dateFromString(schedule.endDate ?? "") ?? NSDate()
        offTimeDatePicker.date = timeFormatter.dateFromString(schedule.endTimeEachDay ?? "") ?? NSDate()
        
        onDatePicker.timeZone = timeZone
        onTimeDatePicker.timeZone = timeZone
        offDatePicker.timeZone = timeZone
        offTimeDatePicker.timeZone = timeZone
        
        utcSwitch.on = schedule.utc
        displayNameTextField.text = schedule.displayName
        
        repeatType = .None
        if let daysOfWeek = schedule.daysOfWeek {
            let intAndNumberArraysAreEqual: ([Int],[NSNumber]) -> Bool = { (intArray, numberArray) in
                var equals = true
                for number in numberArray {
                    if !intArray.contains(number.integerValue) {
                        equals = false
                        break
                    }
                }
                return equals
            }
            if intAndNumberArraysAreEqual([1,7],daysOfWeek) {
                repeatType = .Weekends
            } else if intAndNumberArraysAreEqual(Array(2...6),daysOfWeek) {
                repeatType = .Weekdays
            }
        } else if schedule.endDate == nil || schedule.endDate!.isEmpty {
            repeatType = .Daily
        }
        self.repeatPicker.selectRow(repeatType.rawValue, inComponent: 0, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.actionPicker:
            return ActionType.count
        case self.repeatPicker:
            return RepeatType.count
        default:
            return 0
        }
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerView {
        case self.actionPicker:
            actionType = ActionType(rawValue: row)!
            tableView.beginUpdates()
            tableView.endUpdates()
        case self.repeatPicker:
            repeatType = RepeatType(rawValue: row)!
            offDatePicker.enabled = repeatType != .Daily
        default:
            break
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case self.actionPicker:
            return "\(ActionType(rawValue: row)!.description())"
            
        case self.repeatPicker:
            return "\(RepeatType(rawValue: row)!)"
        default:
            return nil
        }
    }
    
    @IBAction func saveAction(sender: UIButton) {
        let calendar = NSCalendar.currentCalendar()
        
        let startDate = dateFormatter.stringFromDate(onDatePicker.date)
        var startTimeDate : NSDate?
        // remove seconds
        calendar.rangeOfUnit(.Minute, startDate: &startTimeDate, interval: nil, forDate: onTimeDatePicker.date)
        let startTime = timeFormatter.stringFromDate(startTimeDate!)
        
        let endDate = dateFormatter.stringFromDate(offDatePicker.date)
        var endTimeDate : NSDate?
        // remove seconds
        calendar.rangeOfUnit(.Minute, startDate: &endTimeDate, interval: nil, forDate: offTimeDatePicker.date)
        let endTime = timeFormatter.stringFromDate(endTimeDate!)
        
        schedule.displayName = displayNameTextField.text
        
        switch actionType {
        case .TurnOffOn:
            fallthrough
        case .TurnOnOff:
            schedule.startDate = startDate
            schedule.startTimeEachDay = startTime
            schedule.endDate =  repeatType == .Daily ? "" : endDate //use "" temporarily since lib currently doesn't pass nil info to cloud
            schedule.endTimeEachDay = endTime
        case .TurnOn:
            schedule.startDate = startDate
            schedule.startTimeEachDay = startTime
            schedule.endDate = startDate
            schedule.endTimeEachDay = startTime
        case .TurnOff:
            schedule.startDate = endDate
            schedule.startTimeEachDay = endTime
            schedule.endDate = endDate
            schedule.endTimeEachDay = endTime
        }
        
        switch repeatType {
        case .Weekdays:
            schedule.daysOfWeek = Array(2...6) // monday through friday
        case .Weekends:
            schedule.daysOfWeek = [1,7] //sunday and saturday
        case .Daily:
            fallthrough
        case .None:
            schedule.dayOccurOfMonth = nil
            schedule.daysOfMonth = nil
            schedule.daysOfWeek = nil
        }
        
        schedule.utc = utcSwitch.on
        
        atStartAction!.active = true
        atEndAction!.active = true
        atStartAction!.firePoint = .AtStart
        atEndAction!.firePoint = .AtEnd
        switch actionType {
        case .TurnOn:
            atEndAction!.active = false
            fallthrough
        case .TurnOnOff:
            atStartAction!.value = 1
            atEndAction!.value = 0
        case .TurnOff:
            atEndAction!.active = false
            fallthrough
        case .TurnOffOn:
            atStartAction!.value = 0
            atEndAction!.value = 1
        }
        
        saveScheduleButton.enabled = false
        device.updateSchedule(schedule, success: { (schedule) -> Void in
            let actions = [self.atStartAction!, self.atEndAction!]

            self.schedule.updateScheduleActions(actions, success: { (actions) in
                UIAlertController.alert("Success", message: "Saved Schedule", buttonTitle: "OK", fromController: self)
                self.saveScheduleButton.enabled = true
                }, failure: { (error) in
                    self.saveScheduleButton.enabled = true
                    UIAlertController.alert("Error", message: "Could not save schedule(\(error.code))", buttonTitle: "OK", fromController: self)
                    print("Failed to update actions \(error)")
            })
        }) { (error) -> Void in
            self.saveScheduleButton.enabled = true
            UIAlertController.alert("Error", message: "Could not save schedule(\(error.code))", buttonTitle: "OK", fromController: self)
            print("Failed to update schedule \(error)")
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 2 && actionType == .TurnOff {
            return 0
        }
        if indexPath.row == 3 && actionType == .TurnOn {
            return 0
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
}
