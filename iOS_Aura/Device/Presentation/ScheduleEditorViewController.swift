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
    
    private enum RepeatType: Int {
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
    
    private var repeatType = RepeatType.None
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var actionsTitleLabel: UILabel!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var utcSwitch: UISwitch!
    
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
    
    private var dateFormatter : NSDateFormatter! = NSDateFormatter()
    private var timeFormatter : NSDateFormatter! = NSDateFormatter()
    private var timeZone : NSTimeZone! = NSTimeZone.localTimeZone()
    private var actions : [AylaScheduleAction]?
    
    private static let NoActionCellId: String = "NoActionsCellId"
    private static let ActionDetailCellId: String = "ActionDetailCellId"
    
    private let segueToScheduleActionEditorId : String = "toScheduleActionEditor"
    
    var schedule : AylaSchedule? = nil {
        didSet {
            if schedule?.utc != nil {
                timeZone = schedule!.utc ? NSTimeZone(forSecondsFromGMT: 0) : NSTimeZone.localTimeZone()
            }
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = timeZone
            timeFormatter.dateFormat = "HH:mm:ss"
            timeFormatter.timeZone = timeZone
        }
    }
    private var startDate : NSDate? = nil
    private var endDate : NSDate? = nil
    private var startTime : NSDate? = nil
    private var endTime : NSDate? = nil
    
    var device : AylaDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
            self.sessionManager = sessionManager
        }
        else {
            print("- WARNING - session manager can't be found")
        }
        
        displayNameTextField.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self
        startTimeTextField.delegate = self
        endTimeTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(ScheduleEditorViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        addActionButton.tintColor = UIColor.auraLeafGreenColor()
        
        endDateTextField.inputView = UIView()
        startDateTextField.inputView = UIView()
        endTimeTextField.inputView = UIView()
        startTimeTextField.inputView = UIView()
        
        actionsTableView.dataSource = self
        actionsTableView.delegate = self
        
        repeatTextField.delegate = self
        repeatTextField.inputView = UIView()
        repeatPicker.dataSource = self
        repeatPicker.delegate = self
        

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if schedule == nil {
            UIAlertController.alert("Internal Error", message: "Schedule is null.  This should not happen.", buttonTitle: "OK", fromController: self, okHandler: { (action) in
                self.cancel()
            })
        } else {
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
            populateUIFromSchedule()
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.autoResizeActionsTable()
    }
    
    private func autoResizeActionsTable(){
        // Called to adjust autolayout constraints of actions tableview to after adding or removing actions
        let baseHeight = 65
        var height : CGFloat = CGFloat(baseHeight)
        if actions != nil {
            if !actions!.isEmpty {
                height = CGFloat(baseHeight * actions!.count)
            }
        }
        actionsTableViewHeightConstraint.constant = height
        view.layoutIfNeeded()
    }
    
    private func populateUIFromSchedule() {
        // Populate UI elements based on properties of associated schedule.
        if schedule != nil {
            if schedule?.fixedActions == true {
                addActionButton.enabled = false
                actionsTitleLabel.text = "Fixed Schedule Actions"
            }
            else {
                addActionButton.enabled = true
                actionsTitleLabel.text = "Schedule Actions"
            }
            
            startDate = schedule!.startDate != nil ? dateFormatter.dateFromString(schedule!.startDate!) : nil
            endDate = schedule!.endDate != nil ? dateFormatter.dateFromString(schedule!.endDate!) : nil
            
            startTime = schedule!.startTimeEachDay != nil ? timeFormatter.dateFromString(schedule!.startTimeEachDay!) : nil
            
            endTime = schedule!.endTimeEachDay != nil ? timeFormatter.dateFromString(schedule!.endTimeEachDay!) : nil
            
            startDatePicker.timeZone = timeZone
            endDatePicker.timeZone = timeZone
            startTimePicker.timeZone = timeZone
            endTimePicker.timeZone = timeZone
            
            startDatePicker.date = startDate ?? NSDate()
            endDatePicker.date = endDate ?? NSDate()
            startTimePicker.date = startTime ?? NSDate()
            endTimePicker.date = endTime ?? NSDate()
            
            setDateTextFieldValue(startDate, field:startDateTextField)
            setDateTextFieldValue(endDate, field:endDateTextField)
            setTimeTextFieldValue(startTime, field:startTimeTextField)
            setTimeTextFieldValue(endTime, field:endTimeTextField)

            utcSwitch.on = schedule!.utc
            displayNameTextField.text = schedule!.displayName
            activeSwitch.on = schedule!.active
            
            repeatType = .None
            if let daysOfWeek = schedule!.daysOfWeek {
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
            } else if schedule!.endDate == nil || schedule!.endDate!.isEmpty {
                repeatType = .Daily
            }
            self.repeatPicker.selectRow(repeatType.rawValue, inComponent: 0, animated: true)
            repeatTextField.text = "\(RepeatType(rawValue: repeatType.rawValue)!)"
        }
    }
    
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    private func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }

    private func toggleViewVisibilityAnimated(view: UIView){
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.33) {
                view.hidden = !(view.hidden)
            }
        }
    }

    private func setDateTextFieldValue(date: NSDate?, field: UITextField) {
        if date != nil {
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeZone = timeZone
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .NoStyle
            field.text = dateFormatter.stringFromDate(date!)
        } else {
            field.text = ""
        }
    }
    
    private func setTimeTextFieldValue(date: NSDate?, field: UITextField) {
        if date != nil {
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeZone = timeZone
            dateFormatter.dateStyle = .NoStyle
            dateFormatter.timeStyle = .LongStyle
            field.text = dateFormatter.stringFromDate(date!)
        } else {
            field.text = ""
        }
    }

    @IBAction func utcSwitchTapped(sender: UISwitch) {
        timeZone = sender.on ? NSTimeZone(forSecondsFromGMT: 0) : NSTimeZone.localTimeZone()

        dateFormatter.timeZone = timeZone
        timeFormatter.timeZone = timeZone
        
        startDatePicker.timeZone = timeZone
        endDatePicker.timeZone = timeZone
        startTimePicker.timeZone = timeZone
        endTimePicker.timeZone = timeZone
        
        setDateTextFieldValue(startDate, field: startDateTextField)
        setTimeTextFieldValue(startTimePicker.date, field: startTimeTextField)
        setDateTextFieldValue(endDate, field: endDateTextField)
        setTimeTextFieldValue(endTime, field: endTimeTextField)
    }
    
    @IBAction func startDateFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(startDatePicker)
    }
    
    @IBAction func startTimeFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(startTimePicker)
    }

    @IBAction func endDateFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(endDatePicker)
    }
    
    @IBAction func endTimeFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(endTimePicker)
    }
    
    @IBAction func repeatFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(repeatPicker)
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
    
    private func fetchActions(success : ()-> Void, failure : (NSError)->Void) {
        if schedule == nil { return }
        schedule!.fetchAllScheduleActionsWithSuccess({ (actions) in
            // Sort Actions to display AtStart first, then AtEnd, then InRange
            let sortedActions = actions.sort({ $0.firePoint.rawValue < $1.firePoint.rawValue })
            self.actions = sortedActions
            success();
        }) { (error) in
            failure(error);
        }

    }

    private func clearAllActions() {
        if schedule == nil { return }
        let confirmationAlert = UIAlertController(title: "Delete Actions", message: "Are you sure you want to delete all actions associated with this schedule? This will not delete the schedule, just the actions.", preferredStyle: .Alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive) { (action) in
            self.schedule?.deleteAllScheduleActionsWithSuccess({
                self.fetchActions({
                    self.populateUIFromSchedule()
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
        presentViewController(confirmationAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func saveScheduleButtonPressed(sender: AuraButton) {
        if schedule == nil { return }
        let calendar = NSCalendar.currentCalendar()
        
        var startDateString : String? = nil
        var startTimeString : String? = nil
        var endDateString : String? = nil
        var endTimeString : String? = nil
        
        var startTimeDate : NSDate?
        var endTimeDate : NSDate?
        
        if startDate != nil {
            startDateString = dateFormatter.stringFromDate(self.startDate!)
        }
        if startTime != nil {
            // remove seconds
            calendar.rangeOfUnit(.Minute, startDate: &startTimeDate, interval: nil, forDate: self.startTime!)
            startTimeString = timeFormatter.stringFromDate(startTimeDate!)
        }
        if endDate != nil {
            endDateString = dateFormatter.stringFromDate(self.endDate!)
        }
        if endTime != nil {
            // remove seconds
            calendar.rangeOfUnit(.Minute, startDate: &endTimeDate, interval: nil, forDate: self.endTime!)
            endTimeString = timeFormatter.stringFromDate(endTimeDate!)
        }

        schedule!.displayName = displayNameTextField.text
        schedule!.startDate = startDateString
        schedule!.startTimeEachDay = startTimeString
        schedule!.endDate = endDateString
        schedule!.endTimeEachDay = endTimeString
        
        switch repeatType {
        case .Weekdays:
            schedule!.daysOfWeek = Array(2...6) // monday through friday
        case .Weekends:
            schedule!.daysOfWeek = [1,7] //sunday and saturday
        case .Daily:
            fallthrough
        case .None:
            schedule!.dayOccurOfMonth = nil
            schedule!.daysOfMonth = nil
            schedule!.daysOfWeek = nil
        }
        
        schedule!.utc = utcSwitch.on
        saveScheduleButton.enabled = false
        schedule!.active = activeSwitch.on
        
        if let scheduleDevice = self.device {
            scheduleDevice.updateSchedule(schedule!, success: { (schedule) -> Void in
                self.schedule = schedule
                UIAlertController.alert("Success", message: "Schedule Updated sucessfully", buttonTitle: "OK", fromController: self, okHandler: { (action) in
                self.cancel()
                })
                        }) { (error) -> Void in
                self.saveScheduleButton.enabled = true
                UIAlertController.alert("Error", message: "Failed to Save Schedule.\n\n\(error.description)", buttonTitle: "OK", fromController: self)
                print("Failed to update schedule \(error)")
                }
        } else {

            UIAlertController.alert("Error", message: "Cannot find device", buttonTitle: "OK", fromController: self, okHandler: { (action) in
                self.cancel()
            })
        }
    }
    
    // MARK: Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if actions != nil {
            if actions!.isEmpty || actions!.count < 1 {
                return 1
            } else {
                return actions!.count
            }
        }
        else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if actions != nil {
            if !actions!.isEmpty {
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
        if schedule == nil { return }

        if schedule!.fixedActions == true {
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
        if schedule?.fixedActions == true {
            return false
        }
        return actions != nil ? true : false
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if schedule?.fixedActions == true {
            return []
        }
        if let actions = self.actions {
            let deleteActionAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) in
                let schedAction: AylaScheduleAction? = actions[indexPath.row]
                // Delete action
                self.schedule?.deleteScheduleAction(schedAction!, success: {
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

        switch textField {
        case startDateTextField:
            toggleViewVisibilityAnimated(startDatePicker)
            return false
        case endDateTextField:
            toggleViewVisibilityAnimated(endDatePicker)
            return false
        case startTimeTextField:
            toggleViewVisibilityAnimated(startTimePicker)
            return false
        case endTimeTextField:
            toggleViewVisibilityAnimated(endTimePicker)
            return false
        case repeatTextField:
            toggleViewVisibilityAnimated(repeatPicker)
            return false
        default:
            return true
        }
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        // Handle clearing of special text fields and their associated pickers and vars
        switch textField {
        case startDateTextField:
            startDatePicker.reloadInputViews()
            startDate = nil
            return true
        case endDateTextField:
            endDatePicker.reloadInputViews()
            endDate = nil
            return true
        case startTimeTextField:
            return false
        case endTimeTextField:
            endTimePicker.reloadInputViews()
            endTime = nil
            return true
        case repeatTextField:
            repeatPicker.reloadInputViews()
            return true
        default:
            return false
        }
    }
    
    
    // MARK: - UIPickerView Datasource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case repeatPicker:
            return RepeatType.count
        default:
            return 0
        }
    }
    
    
    // MARK: - UIPickerView Delegate

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case repeatPicker:
            repeatType = RepeatType(rawValue: row)!
            repeatTextField.text = "\(RepeatType(rawValue: row)!)"
        default:
            break
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case repeatPicker:
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
            scheduleActionEditorController.schedule = schedule
            if sender != nil {
                scheduleActionEditorController.action = (sender as! AylaScheduleAction)
            }
        }
        else {
            
        }
    }
}