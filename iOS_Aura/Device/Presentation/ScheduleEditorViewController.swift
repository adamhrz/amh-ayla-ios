//
//  ScheduleEditorViewController.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 7/11/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleEditorViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate{
    
    var sessionManager : AylaSessionManager?
    
    var startDate : NSDate?
    var endDate : NSDate?
    
    var startTime : NSDate?
    var endTime : NSDate?
    
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
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var actionsTitleLabel: UILabel!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var utcSwitch: UISwitch!
    @IBOutlet weak var activeSwitch: UISwitch!
    
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var startTimeTextField: UITextField!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var endTimeTextField: UITextField!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    
    @IBOutlet weak var repeatTextField: UITextField!
    @IBOutlet weak var repeatPicker: UIPickerView!
    @IBOutlet weak var saveScheduleButton: AuraButton!
    
    @IBOutlet weak var addActionButton: UIButton!
    @IBOutlet weak var actionsTableView : UITableView!
    @IBOutlet weak var actionsTableViewHeightConstraint: NSLayoutConstraint!
    
    var dateFormatter : NSDateFormatter!
    var timeFormatter : NSDateFormatter!
    var combinedDateFormatter : NSDateFormatter!

    var timeZone : NSTimeZone!
    
    var propertyNames : [String]!
    var actions : [AylaScheduleAction]?
    
    static let NoActionCellId: String = "NoActionsCellId"
    static let ActionDetailCellId: String = "ActionDetailCellId"
    
    let segueToScheduleActionEditorId : String = "toScheduleActionEditor"
    
    var schedule : AylaSchedule! = nil {
        didSet {
            timeZone = schedule.utc ? NSTimeZone(forSecondsFromGMT: 0) : NSTimeZone.localTimeZone()
            
            dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = timeZone
            
            timeFormatter = NSDateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            timeFormatter.timeZone = timeZone
            
            combinedDateFormatter = NSDateFormatter()
            combinedDateFormatter.dateFormat = "yyyy-MM-ddHH:mm:ss"
            combinedDateFormatter.timeZone = timeZone
            
            // Filter and store all to device property names
            let allProperties = self.schedule.device!.properties!.map { $0.1 } as! [AylaProperty]
            self.propertyNames = allProperties.filter{ $0.direction == AylaScheduleDirectionToDevice }.map{ $0.name }

        }
    }
    
    var device : AylaDevice!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
            self.sessionManager = sessionManager
        }
        else {
            print("- WARNING - session manager can't be found")
        }
        
        self.displayNameTextField.delegate = self
        self.startDateTextField.delegate = self
        self.endDateTextField.delegate = self
        self.startTimeTextField.delegate = self
        self.endTimeTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(ScheduleEditorViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        self.addActionButton.tintColor = UIColor.auraLeafGreenColor()
        
        self.endDateTextField.inputView = UIView()
        self.startDateTextField.inputView = UIView()
        self.endTimeTextField.inputView = UIView()
        self.startTimeTextField.inputView = UIView()
        
        self.actionsTableView.dataSource = self
        self.actionsTableView.delegate = self
        
        self.repeatTextField.delegate = self
        self.repeatTextField.inputView = UIView()
        self.repeatPicker.dataSource = self
        self.repeatPicker.delegate = self
        

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Fetch and refresh actions fresh every time page is displayed.
        fetchActions({
            print("Fetched Actions.  Total count \(self.actions!.count)")
            if let table = self.actionsTableView {
                table.reloadData()
                self.autoResizeActionsTable()
            }
            }) { (error) in
                UIAlertController.alert("Failed to fetch actions", message: error.description, buttonTitle: "OK", fromController: self)
        }
        updateUIFromSchedule()
    }
    
    override func viewDidLayoutSubviews() {
        self.autoResizeActionsTable()
    }
    
    private func autoResizeActionsTable(){
        // Called to adjust autolayout constraints of actions tableview to after adding or removing actions
        let baseHeight = 65
        var height : CGFloat = CGFloat(baseHeight)
        if let count = self.actions?.count {
            height = CGFloat(baseHeight * count)
        }
        self.actionsTableViewHeightConstraint.constant = height
        self.view.layoutIfNeeded()
    }
    
    func updateUIFromSchedule() {
        // Populate UI elements based on properties of associated schedule.
        if schedule.fixedActions == true {
            addActionButton.enabled = false
            actionsTitleLabel.text = "Fixed Schedule Actions"
        }
        else {
            addActionButton.enabled = true
            actionsTitleLabel.text = "Schedule Actions"
        }
        
        startDate = dateFormatter.dateFromString(schedule.startDate != nil ? (schedule.startDate!) : "") ?? NSDate()
        endDate = dateFormatter.dateFromString(schedule.endDate != nil ? (schedule.endDate!) : "") ?? NSDate()
        startTime = timeFormatter.dateFromString(schedule.startTimeEachDay != nil ? schedule.startTimeEachDay! : "") ?? NSDate()
        endTime = timeFormatter.dateFromString(schedule.endTimeEachDay != nil ? schedule.endTimeEachDay! : "") ?? NSDate()
        
        startDatePicker.timeZone = timeZone
        endDatePicker.timeZone = timeZone
        startTimePicker.timeZone = timeZone
        endTimePicker.timeZone = timeZone
        
        startDatePicker.date = startDate!
        endDatePicker.date = endDate!
        startTimePicker.date = startTime!
        endTimePicker.date = endTime!
        
        setDateTextFieldValue(startDatePicker.date, field:startDateTextField)
        setDateTextFieldValue(endDatePicker.date, field:endDateTextField)
        setTimeTextFieldValue(startTimePicker.date, field:startTimeTextField)
        setTimeTextFieldValue(endTimePicker.date, field:endTimeTextField)

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
        repeatTextField.text = "\(RepeatType(rawValue: repeatType.rawValue)!)"
    }
    
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    func cancel() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func toggleViewVisibilityAnimated(view: UIView){
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.33) {
                view.hidden = !(view.hidden)
            }
        }
    }

    func setDateTextFieldValue(date: NSDate, field: UITextField) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        field.text = dateFormatter.stringFromDate(date)
    }
    
    func setTimeTextFieldValue(date: NSDate, field: UITextField) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateStyle = .NoStyle
        dateFormatter.timeStyle = .LongStyle
        field.text = dateFormatter.stringFromDate(date)
    }

    @IBAction func utcSwitchTapped(sender: UISwitch) {
        timeZone = sender.on ? NSTimeZone(forSecondsFromGMT: 0) : NSTimeZone.localTimeZone()

        dateFormatter.timeZone = timeZone
        timeFormatter.timeZone = timeZone
        
        self.setDateTextFieldValue(startDatePicker.date, field: startDateTextField)
        self.setTimeTextFieldValue(startTimePicker.date, field: startTimeTextField)
        self.setDateTextFieldValue(endDatePicker.date, field: endDateTextField)
        self.setTimeTextFieldValue(endTimePicker.date, field: endTimeTextField)
    }
    
    @IBAction func startDateFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(self.startDatePicker)
    }
    
    @IBAction func startTimeFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(self.startTimePicker)
    }

    @IBAction func endDateFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(self.endDatePicker)
    }
    
    @IBAction func endTimeFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(self.endTimePicker)
    }
    
    @IBAction func repeatFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(self.repeatPicker)
    }
    
    @IBAction func startDatePickerChanged(sender: UIDatePicker) {
        startDate = sender.date
        setDateTextFieldValue(startDate!, field:startDateTextField)
    }

    @IBAction func endDatePickerChanged(sender: UIDatePicker) {
        endDate = sender.date
        setDateTextFieldValue(endDate!, field:endDateTextField)
    }
    
    @IBAction func startTimePickerChanged(sender: UIDatePicker) {
        startTime = sender.date
        setTimeTextFieldValue(startTime!, field:startTimeTextField)
    }
    
    @IBAction func endTimePickerChanged(sender: UIDatePicker) {
        endTime = sender.date
        setTimeTextFieldValue(endTime!, field:endTimeTextField)
    }
    
    @IBAction func addScheduleActionButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueToScheduleActionEditorId, sender: nil)
    }
    
    // MARK: Schedule Handling Methods
    
    func fetchActions(success : ()-> Void, failure : (NSError)->Void) {
        schedule.fetchAllScheduleActionsWithSuccess({ (actions) in
            // Sort Actions to display AtStart first, then AtEnd, then InRange
            let sortedActions = actions.sort({ $0.firePoint.rawValue < $1.firePoint.rawValue })
            self.actions = sortedActions
            success();
        }) { (error) in
            failure(error);
        }
    }

    func clearAllActions() {
        let confirmationAlert = UIAlertController(title: "Delete Actions", message: "Are you sure you want to delete all actions associated with this schedule? This will not delete the schedule, just the actions.", preferredStyle: .Alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive) { (action) in
            self.schedule.deleteAllScheduleActionsWithSuccess({
                self.fetchActions({
                    self.updateUIFromSchedule()
                    UIAlertController.alert("Success", message: "Deleted all schedule actions", buttonTitle: "OK", fromController: self)
                    }, failure: { (error) in
                        UIAlertController.alert("Error", message: "Could not update action status\n\n\(error.description)", buttonTitle: "OK", fromController: self)
                        print("Failed to update actions, status: \(error)")
                })
            }) { (error) in
                UIAlertController.alert("Error", message: "Could not delete actions\n\n\(error.description)", buttonTitle: "OK", fromController: self)
                print("Failed to delete actions \(error)")
            }
        }
        confirmationAlert.addAction(confirmAction)
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(confirmationAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func saveScheduleButtonPressed(sender: AuraButton) {
        let calendar = NSCalendar.currentCalendar()
        
        let startDateString = dateFormatter.stringFromDate(self.startDate!)
        var startTimeDate : NSDate?
        // remove seconds
        calendar.rangeOfUnit(.Minute, startDate: &startTimeDate, interval: nil, forDate: self.startTime!)
        let startTimeString = timeFormatter.stringFromDate(startTimeDate!)
        
        let endDateString = dateFormatter.stringFromDate(self.endDate!)
        var endTimeDate : NSDate?
        // remove seconds
        calendar.rangeOfUnit(.Minute, startDate: &endTimeDate, interval: nil, forDate: self.endTime!)
        let endTimeString = timeFormatter.stringFromDate(endTimeDate!)
        
        schedule.displayName = displayNameTextField.text
        
        schedule.startDate = startDateString
        schedule.startTimeEachDay = startTimeString
        schedule.endDate = endDateString
        schedule.endTimeEachDay = endTimeString
        
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
        saveScheduleButton.enabled = false

        schedule.active = activeSwitch.on
        device.updateSchedule(schedule, success: { (schedule) -> Void in
            
                    }) { (error) -> Void in
            self.saveScheduleButton.enabled = true
            UIAlertController.alert("Error", message: "Failed to Save Schedule.\n\n\(error.description)", buttonTitle: "OK", fromController: self)
            print("Failed to update schedule \(error)")
        }
    }
    
    // MARK: Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.actions?.count {
            return count > 0 ? count : 1
        }
        else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let count = self.actions?.count {
            if count > 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(ScheduleEditorViewController.ActionDetailCellId) as! ScheduleEditorActionTableViewCell
                cell.backgroundColor = UIColor.whiteColor()
                cell.configure(self.actions![indexPath.row])
                return cell
            } else {
                let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier(ScheduleEditorViewController.NoActionCellId)!
                cell.backgroundColor = UIColor.clearColor()
                return cell
            }
        } else {
            let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier(ScheduleEditorViewController.NoActionCellId)!
            cell.backgroundColor = UIColor.clearColor()
            return cell
        }

    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 65
    }
    
    
    // MARK: Table View Delegate    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if schedule.fixedActions == true {
            UIAlertController.alert("Fixed Actions", message: "This schedule has fixed actions which cannot be edited.", buttonTitle: "OK", fromController: self)
        } else {
            if let actions = self.actions {
                if actions.count > 0 {
                    performSegueWithIdentifier(segueToScheduleActionEditorId, sender: actions[indexPath.row])
                }
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Only allow editing of rows for non-fixed actions
        if schedule.fixedActions == true {
            return false
        }
        return self.actions != nil ? true : false
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if schedule.fixedActions == true {
            return []
        }
        if let actions = self.actions {
            let deleteActionAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) in
                let schedAction: AylaScheduleAction? = actions[indexPath.row]
                // Delete action
                self.schedule.deleteScheduleAction(schedAction!, success: {
                    // Fetch fresh actions once deletion is finished
                    self.fetchActions({
                        tableView.reloadData()
                        self.autoResizeActionsTable()
                        }, failure: { (error) in
                            UIAlertController.alert("Failed to Refresh Actions", message: error.description, buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                                tableView.reloadData()
                            })
                    })
                    
                    }, failure: { (error) in
                        UIAlertController.alert("Failed to Delete Action", message: error.description, buttonTitle: "OK", fromController: self)
                        tableView.reloadData()
                })
            }
            deleteActionAction.backgroundColor = UIColor.auraRedColor()
            return [deleteActionAction]
        }

        return []
    }
    
    
    // MARK: Text Field Delegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        // Disallow certain text fields from being manually edited
        if textField == self.startDateTextField {
            toggleViewVisibilityAnimated(startDatePicker)
            return false
        } else if textField == self.startTimeTextField {
            toggleViewVisibilityAnimated(startTimePicker)
            return false
        } else if textField == self.endDateTextField {
            toggleViewVisibilityAnimated(endDatePicker)
            return false
        } else if textField == self.endTimeTextField {
                toggleViewVisibilityAnimated(endTimePicker)
                return false
        } else if textField == self.repeatTextField {
            toggleViewVisibilityAnimated(repeatPicker)
            return false
        } else {
            return true
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        // Handle clearing of special text fields and their associated pickers and vars
        if textField == self.startDateTextField {
            startDatePicker.reloadInputViews()
            startDate = nil
            return true
        } else if textField == self.endDateTextField {
            endDatePicker.reloadInputViews()
            endDate = nil
            return true
        } else if textField == self.startTimeTextField {
            startTimePicker.reloadInputViews()
            startTime = nil
            return true
        } else if textField == self.endTimeTextField {
            endTimePicker.reloadInputViews()
            endTime = nil
            return true
        } else if textField == self.repeatTextField {
            repeatPicker.reloadInputViews()
            return true
        } else {
            return false
        }
    }
    
    
    // MARK: - UIPickerView Datasource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.repeatPicker:
            return RepeatType.count
        default:
            return 0
        }
    }
    
    
    // MARK: - UIPickerView Delegate

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case self.repeatPicker:
            repeatType = RepeatType(rawValue: row)!
            repeatTextField.text = "\(RepeatType(rawValue: row)!)"
        default:
            break
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case self.repeatPicker:
            return "\(RepeatType(rawValue: row)!)"
        default:
            return nil
        }
    }
    
    
    // MARK: - Navigation
        
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueToScheduleActionEditorId {
            let scheduleActionEditorController = segue.destinationViewController as! ScheduleActionEditorViewController
            scheduleActionEditorController.device = device
            scheduleActionEditorController.schedule = schedule
            if sender != nil {
                scheduleActionEditorController.action = (sender as! AylaScheduleAction)
            }
        }
        else {
            
        }
    }
}