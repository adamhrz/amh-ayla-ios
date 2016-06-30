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
    @IBOutlet weak var propertyPicker: UIPickerView!
    @IBOutlet weak var activeSwitch: UISwitch!
    
    var dateFormatter : NSDateFormatter!
    var timeFormatter : NSDateFormatter!
    var timeZone : NSTimeZone!
    
    var atStartAction : AylaScheduleAction?
    var atEndAction : AylaScheduleAction?
    var properties : [String]!
    var actions : [AylaScheduleAction]?
    
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
            
            //fetch bool, toDevice managed properties
            let allProperties = self.schedule.device!.properties!.map { $0.1 } as! [AylaProperty]
            self.properties = allProperties.filter{ $0.direction == AylaScheduleDirectionToDevice }.map{ $0.name }

            fetchActions({
                
                if self.actions!.count != 2 && self.schedule.fixedActions {
                    
                    UIAlertController.alert("Error", message: "Schedule configuration error. No actions found for a fixed action schedule.", buttonTitle: "OK", fromController: self) {_ in 
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                    print("Schedule with fixed actions has actions.cound != 2")
                }
                
                }) { (error) in
                    print(error.userInfo)
            }
            if  !self.schedule.fixedActions {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(clearAllActions))
            }
        }
    }
    
    var device : AylaDevice!
    
    func fetchActions(success : ()-> Void, failure : (NSError)->Void) {
        schedule.fetchAllScheduleActionsWithSuccess({ (actions) in
            self.actions = actions
            //determine wether to create or use existing actions
            switch actions.count {
            case 0:
                self.atStartAction = AylaScheduleAction(name: self.schedule.name, value: 0, baseType: AylaPropertyBaseTypeBoolean, active: true, firePoint: .AtStart, schedule: self.schedule)
                self.atEndAction = AylaScheduleAction(name: self.schedule.name, value: 1, baseType: AylaPropertyBaseTypeBoolean, active: true, firePoint: .AtEnd, schedule: self.schedule)
            case 1:
                self.atStartAction = actions.first
                self.atEndAction = AylaScheduleAction(name: self.schedule.name, value: 1, baseType: AylaPropertyBaseTypeBoolean, active: true, firePoint: .AtEnd, schedule: self.schedule)
            default:
                if actions.first?.firePoint == .AtStart {
                    self.atStartAction = actions.first
                    self.atEndAction = actions.last
                } else {
                    self.atStartAction = actions.last
                    self.atEndAction = actions.first
                }
            }
            
            let propertyName = self.atStartAction!.name
            if let propertyNameIndex = self.properties.indexOf(propertyName) {
                self.propertyPicker.selectRow(propertyNameIndex, inComponent: 0, animated: true)
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
            success();
        }) { (error) in
            failure(error);
        }
    }
    
    func clearAllActions() {
        let confirmationAlert = UIAlertController(title: "Delete Actions", message: "Are you sure you want to delete all actions of this schedule? This will not delete the schedule, just the actions.", preferredStyle: .Alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive) { (action) in
            self.schedule.deleteAllScheduleActionsWithSuccess({
                self.fetchActions({
                    self.updateUI()
                    UIAlertController.alert("Success", message: "Deleted all schedule actions", buttonTitle: "OK", fromController: self)
                    }, failure: { (error) in
                        UIAlertController.alert("Error", message: "Could not update action status(\(error.code))", buttonTitle: "OK", fromController: self)
                        print("Failed to update action status \(error)")
                })
            }) { (error) in
                UIAlertController.alert("Error", message: "Could not delete actions(\(error.code))", buttonTitle: "OK", fromController: self)
                print("Failed to delete actions \(error)")
            }
        }
        confirmationAlert.addAction(confirmAction)
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(confirmationAlert, animated: true, completion: nil)
    }
    
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
        activeSwitch.on = schedule.active
        
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
        case self.propertyPicker:
            return properties.count
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
            
        case self.propertyPicker:
            return properties[row]
            
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
          schedule.startDate = endDate
          schedule.startTimeEachDay = endTime
          schedule.endDate =  repeatType == .Daily ? "" : startDate //use "" temporarily since lib currently doesn't pass nil info to cloud
          schedule.endTimeEachDay = startTime
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
        
        let propertyName = properties[self.propertyPicker.selectedRowInComponent(0)]
        
        atEndAction!.name = propertyName
        atStartAction!.name = propertyName
        
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
        
        // determine what actions to create and what to update
        var existingActions = [AylaScheduleAction]()
        var actionsToCreate = [AylaScheduleAction]()
        if self.atStartAction!.key == nil {
            actionsToCreate.append(self.atStartAction!)
        } else {
            existingActions.append(self.atStartAction!)
        }
        
        if self.atEndAction!.key == nil {
            actionsToCreate.append(self.atEndAction!)
        } else {
            existingActions.append(self.atEndAction!)
        }
        
        schedule.active = activeSwitch.on
        saveScheduleButton.enabled = false
        device.updateSchedule(schedule, success: { (schedule) -> Void in
            
            let createUpdateGroup = dispatch_group_create()
            var errors = [NSError]()
            if existingActions.count > 0 {
                dispatch_group_enter(createUpdateGroup)
                self.schedule.updateScheduleActions(existingActions, success: { (actions) in
                    dispatch_group_leave(createUpdateGroup)
                    }, failure: { (error) in
                        errors.append(error)
                        dispatch_group_leave(createUpdateGroup)
                })
            }
            
            if actionsToCreate.count > 0 {
                for action in actionsToCreate {
                    dispatch_group_enter(createUpdateGroup)
                    self.schedule.createScheduleAction(action, success: { (createdAction) in
                        dispatch_group_leave(createUpdateGroup)
                        }, failure: { (error) in
                            errors.append(error)
                            dispatch_group_leave(createUpdateGroup)
                    })
                }
            }
            
            dispatch_group_notify(createUpdateGroup, dispatch_get_main_queue(), {
                if let error = errors.first {
                    self.saveScheduleButton.enabled = true
                    UIAlertController.alert("Error", message: "Could not save schedule(\(error.code))", buttonTitle: "OK", fromController: self)
                    print("Failed to update actions \(error)")
                } else {
                    self.fetchActions({
                        UIAlertController.alert("Success", message: "Saved Schedule", buttonTitle: "OK", fromController: self)
                        self.saveScheduleButton.enabled = true
                        }, failure: { (error) in
                            
                            UIAlertController.alert("Error", message: "Could not refresh actions(\(error.code))", buttonTitle: "OK", fromController: self)
                            print("Failed to fetch actions \(error)")
                    })
                }
            })
        }) { (error) -> Void in
            self.saveScheduleButton.enabled = true
            UIAlertController.alert("Error", message: "Could not save schedule(\(error.code))", buttonTitle: "OK", fromController: self)
            print("Failed to update schedule \(error)")
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 3 && actionType == .TurnOff {
            return 0
        }
        if indexPath.row == 4 && actionType == .TurnOn {
            return 0
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
}
