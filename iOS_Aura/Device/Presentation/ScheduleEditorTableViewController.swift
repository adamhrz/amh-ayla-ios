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
    
    var dateFormatter : NSDateFormatter!
    var timeFormatter : NSDateFormatter!
    var timeZone : NSTimeZone!
    
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
    
    var repeatType = RepeatType.None
    
    var schedule : AylaSchedule! = nil {
        didSet {
            timeZone = schedule.utc ? NSTimeZone(forSecondsFromGMT: 0) : NSTimeZone.localTimeZone()
            
            dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = timeZone
            
            timeFormatter = NSDateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            timeFormatter.timeZone = timeZone
        }
    }
    
    var device : AylaDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }
    
    func updateUI() {
        let onDate = dateFormatter.dateFromString(schedule.startDate ?? "")
        onDatePicker.date = onDate ?? NSDate()
        onTimeDatePicker.date = timeFormatter.dateFromString(schedule.startTimeEachDay ?? "") ?? NSDate()
        offDatePicker.date = dateFormatter.dateFromString(schedule.endDate ?? "") ?? NSDate()
        offTimeDatePicker.date = timeFormatter.dateFromString(schedule.endTimeEachDay ?? "") ?? NSDate()
        
        onDatePicker.timeZone = timeZone
        onTimeDatePicker.timeZone = timeZone
        offDatePicker.timeZone = timeZone
        offTimeDatePicker.timeZone = timeZone
        
        utcSwitch.on = schedule.utc
        displayNameTextField.text = schedule.displayName
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return RepeatType.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        repeatType = RepeatType(rawValue: row)!
        offDatePicker.enabled = repeatType != .Daily

        return "\(repeatType)"
    }
    
    @IBAction func saveAction(sender: UIButton) {
        let startDate = dateFormatter.stringFromDate(onDatePicker.date)
        let startTime = timeFormatter.stringFromDate(onTimeDatePicker.date)
        let endDate = dateFormatter.stringFromDate(offDatePicker.date)
        let endTime = timeFormatter.stringFromDate(offTimeDatePicker.date)
        
        schedule.displayName = displayNameTextField.text
        schedule.startDate = startDate
        schedule.startTimeEachDay = startTime
        schedule.endDate =  repeatType == .Daily ? nil : endDate
        schedule.endTimeEachDay = endTime
        
        switch repeatType {
        case .None:
            schedule.dayOccurOfMonth = nil
            schedule.daysOfMonth = nil
            schedule.daysOfWeek = nil
        case .Weekdays:
            schedule.daysOfWeek = Array(2...6) // monday through friday
        case .Weekends:
            schedule.daysOfWeek = [1,7] //sunday and saturday
        case .Daily:
            //do nothing, it's already been taken care of
            fallthrough
        default: break
        }
        
        schedule.utc = utcSwitch.on
        
        saveScheduleButton.enabled = false
        device.updateSchedule(schedule, success: { (schedule) -> Void in
            self.schedule = schedule
            self.updateUI()
            UIAlertController.alert("Success", message: "Saved Schedule", buttonTitle: "OK", fromController: self)
            self.saveScheduleButton.enabled = true
        }) { (error) -> Void in
            self.saveScheduleButton.enabled = true
            UIAlertController.alert("Error", message: "Could not save schedule", buttonTitle: "OK", fromController: self)
        }
    }
}
