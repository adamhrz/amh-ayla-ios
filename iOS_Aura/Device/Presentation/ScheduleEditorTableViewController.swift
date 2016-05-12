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
    
    var schedule : AylaSchedule!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }
    
    func updateUI() {
        let timeZone = schedule.utc ? NSTimeZone(forSecondsFromGMT: 0) : NSTimeZone.localTimeZone()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        dateFormatter.timeZone = timeZone
        
        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.timeZone = timeZone
        
        onDatePicker.date = dateFormatter.dateFromString(schedule.startDate ?? "") ?? NSDate()
        onTimeDatePicker.date = timeFormatter.dateFromString(schedule.startTimeEachDay ?? "") ?? NSDate()
        offDatePicker.date = dateFormatter.dateFromString(schedule.endDate ?? "") ?? NSDate()
        offTimeDatePicker.date = timeFormatter.dateFromString(schedule.endTimeEachDay ?? "") ?? NSDate()
        
        onDatePicker.timeZone = timeZone
        onTimeDatePicker.timeZone = timeZone
        offDatePicker.timeZone = timeZone
        offTimeDatePicker.timeZone = timeZone
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
        return "\(RepeatType(rawValue: row)!)"
    }
}
