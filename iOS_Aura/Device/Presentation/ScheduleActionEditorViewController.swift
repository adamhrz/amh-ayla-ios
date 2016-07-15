//
//  ScheduleActionEditorViewController.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 7/12/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleActionEditorViewController: UIViewController, UITextFieldDelegate,  UIPickerViewDataSource, UIPickerViewDelegate{
    
    var sessionManager : AylaSessionManager?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var parentScheduleNameLabel: UILabel!
    
    @IBOutlet weak var activeSwitch: UISwitch!

    @IBOutlet weak var propertyPicker: UIPickerView!
    @IBOutlet weak var propertyTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var saveActionButton: AuraButton!

    @IBOutlet weak var valueLineItem: UIStackView!
    @IBOutlet weak var firePointSelector: UISegmentedControl!
    
    var properties : [AylaProperty]!
    var propertyNames : [String]!

    var selectedProperty : AylaProperty? = nil {
        didSet{
            self.selectedPropertyBaseType = selectedProperty!.baseType
            self.valueLineItem.hidden = self.selectedProperty == nil ? true : false
        }
    }
    
    var selectedPropertyBaseType : String? = nil {
        didSet {
            self.valueTextField.keyboardType = self.keyboardTypeForPropertyBaseType(self.selectedPropertyBaseType)
        }
    }
    var selectedValue : AnyObject?
    var selectedFirePoint : AylaScheduleActionFirePoint?
    
    var actions : [AylaScheduleAction]?
    var action : AylaScheduleAction? = nil
    
    var device : AylaDevice!
    
    static let NoActionCellId: String = "NoActionsCellId"
    static let ActionDetailCellId: String = "ActionDetailCellId"
    
    var schedule : AylaSchedule! = nil {
        didSet {
            
            // Once retrived from the schedule, store all properties for which an action can be created
            let allProperties = self.schedule.device!.properties!.map { $0.1 } as! [AylaProperty]
            self.properties = allProperties.filter{ $0.direction == AylaScheduleDirectionToDevice }.filter{ ["boolean", "string", "integer", "decimal"].contains($0.baseType) }.map{ $0 }
            self.propertyNames = self.properties.map{ $0.name }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
            self.sessionManager = sessionManager
        }
        else {
            print("- WARNING - session manager can't be found")
        }
        
        let cancel = UIBarButtonItem(barButtonSystemItem:.Cancel, target: self, action: #selector(ScheduleActionEditorViewController.cancel))
        self.navigationItem.leftBarButtonItem = cancel
        
        self.propertyTextField.delegate = self
        self.valueTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(ScheduleActionEditorViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false

        view.addGestureRecognizer(tap)
        
        self.propertyTextField.inputView = UIView()
        self.propertyPicker.dataSource = self
        self.propertyPicker.delegate = self

        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if action != nil {
            updateUIFromScheduleAction()
            self.titleLabel.text = "Edit Schedule Action"
            self.saveActionButton.titleLabel?.text = "Update Action"
        } else {
            parentScheduleNameLabel.text = schedule.displayName
            self.titleLabel.text = "Create Schedule Action"
            self.saveActionButton.titleLabel?.text = "Create Action"
            selectedFirePoint = AylaScheduleActionFirePoint(rawValue: UInt(firePointSelector.selectedSegmentIndex + 1))
        }
        firePointSelector.tintColor = UIColor.auraLeafGreenColor()
    }

    
    func updateUIFromScheduleAction() {
        // Populate UI elements based on properties of a received schedule action
        let propertyName = self.action!.name
        if let propertyNameIndex = self.propertyNames.indexOf(propertyName) {
            self.propertyPicker.selectRow(propertyNameIndex, inComponent: 0, animated: true)
            let property = properties[propertyNameIndex]
            self.propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
            self.selectedProperty = property
        }
        
        self.valueTextField.text = String(self.action!.value)
        self.firePointSelector.selectedSegmentIndex = Int(action!.firePoint.rawValue - 1)
        parentScheduleNameLabel.text = schedule.displayName
        activeSwitch.on = action!.active

    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func cancel() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func toggleViewVisibilityAnimated(view: UIView){
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.33) {
                view.hidden = !(view.hidden)
            }
        }
    }

    @IBAction func propertyFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(self.propertyPicker)
        if selectedProperty == nil {
            let property = properties[propertyPicker.selectedRowInComponent(0)]
            selectedProperty = property
            self.propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
        }
    }

    @IBAction func segmentedControlChanged(sender: UISegmentedControl){
        selectedFirePoint = AylaScheduleActionFirePoint(rawValue: UInt(sender.selectedSegmentIndex + 1))
    }
    // MARK: Schedule Handling Methods
    
    private func propertyAndBaseTypeStringForProperty(property: AylaProperty) -> String{
        return property.name + " (" + property.baseType + ")"
    }
    
    func checkAllRequiredFields() -> Bool{
        // Verify that all required properties have a value set and show alerts for missing ones.
        var message : String? = nil
        if self.selectedProperty == nil {
            message = "You must select a property."
        } else if self.selectedValue == nil {
            message = "You must enter a valid value for the property."
        } else if self.selectedFirePoint == nil {
            message = "You must select a fire point for the action."
        }
        if message != nil {
            UIAlertController.alert("Error", message: message, buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                return false
            })
        }
        else {
            return true
        }
        UIAlertController.alert("Error", message: "An unknown problem has occurred.", buttonTitle: "OK", fromController: self)
        return false
    }
    
    @IBAction func saveActionButtonPressed(sender: AnyObject) {
        // If an action is present try to update it, otherwise, create a new one.
        self.saveActionButton.enabled = false
        if action != nil {
            // Presence of a key indicates it exists on the service and should be updated
            if action!.key != nil {
                updateScheduleAction(action!, successHandler: {
                    self.cancel()
                    }, failureHandler: { (error) in
                self.saveActionButton.enabled = true
                })
            } else{
                // Lack of key indicates action is new/local and needs to be created.
                createNewScheduleAction({
                    self.cancel()
                    }, failureHandler: { (error) in
                        self.saveActionButton.enabled = true
                })
            }
        } else {
            createNewScheduleAction({ 
                self.cancel()
                }, failureHandler: { (error) in
            self.saveActionButton.enabled = true
            })
        }
    }
    
    
    func updateScheduleAction(action: AylaScheduleAction, successHandler: (() -> Void)?, failureHandler: ((error: NSError) -> Void)?){
        // Make a copy of exisiting action
        let actionToUpdate : AylaScheduleAction = self.action!.copy() as! AylaScheduleAction
        
        // Pull settings from UI and change existing schedule action accordingly
        if let property = self.selectedProperty {
            actionToUpdate.name = property.name
            actionToUpdate.baseType = property.baseType
        }
        if let newValue = self.selectedValue {
            actionToUpdate.value = newValue
        }
        
        if let newFirePoint = self.selectedFirePoint {
            actionToUpdate.firePoint = newFirePoint
        }
        actionToUpdate.active = activeSwitch.on

        
        schedule.updateScheduleActions([actionToUpdate], success: { (action) in
            UIAlertController.alert("Success", message: "Action Successfully Updated", buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                if let success = successHandler {
                    success()
                }
            })
            }) { (error) in
                UIAlertController.alert("Failed to Update Action", message: error.description, buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                    if let failure = failureHandler {
                        failure(error:error)
                    }
                })
        }
    }
    
    func createNewScheduleAction(successHandler: (() -> Void)?, failureHandler: ((error: NSError) -> Void)?){
        if checkAllRequiredFields() == true {
            let value = selectedValue
            let name = selectedProperty!.name
            
            let newAction = AylaScheduleAction(name: name, value:value!, baseType: selectedPropertyBaseType!, active: activeSwitch.on, firePoint: selectedFirePoint!, schedule: schedule)
            schedule.createScheduleAction(newAction, success: { (action) in
                    UIAlertController.alert("Success", message: "Action Successfully Created", buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                        self.action = action
                        if let success = successHandler {
                            success()
                        }
                    })
                }) { (error) in

                    UIAlertController.alert("Failed to Update Action", message: error.description, buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                        if let failure = failureHandler {
                            failure(error:error)
                        }
                    })
            }
        }
    }
        
    
    // MARK: Text Field Delegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == self.propertyTextField {
            toggleViewVisibilityAnimated(propertyPicker)
            if selectedProperty == nil {
                let property = properties[propertyPicker.selectedRowInComponent(0)]
                selectedProperty = property
                self.propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
            }
            return false
        } else {
            
            return true
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if textField == self.propertyTextField {
            propertyPicker.reloadInputViews()
            //property = nil
            return true
        } else {
            return false
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
    
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        if textField == self.valueTextField {
            if self.validateStringInputForPropertyBaseType(textField.text, baseType: selectedPropertyBaseType) == true {
                self.selectedValue = valueForStringAndPropertyBaseType(textField.text, baseType: selectedPropertyBaseType)
                return true
            }
            else {
                UIAlertController.alert("Invalid Value", message: "Invalid Value for selected property.", buttonTitle: "OK", fromController: self)
                return false
            }
        }
        else {
            return true
        }
    }
    
    func valueForStringAndPropertyBaseType(str:String?, baseType: String!) -> AnyObject? {
        // Given a string, and a target baseType, return a valid action.value if possible, otherwise nil.
        if str == nil {
            return nil
        }
        switch baseType{
        case AylaPropertyBaseTypeString:
            return str;
        case AylaPropertyBaseTypeBoolean:
            if str == "1" {
                return 1
            }
            if str == "0" {
                return 0
            }
            return nil
        case AylaPropertyBaseTypeInteger:
            if let intValue = Int(str!) {
                return intValue
            }
            return nil
        case AylaPropertyBaseTypeDecimal:
            if let doubleValue = Double(str!) {
                return doubleValue
            }
            return nil
        default:
            return nil
        }

    }
    
    func validateStringInputForPropertyBaseType(str:String?, baseType: String!) -> Bool {
        // Given a string, and a target baseType, return a boolean for whether the string is a valid action.value.
        switch baseType{
        case AylaPropertyBaseTypeString:
            return true;
        case AylaPropertyBaseTypeBoolean:
            if str == "1" || str == "0" {
                return true
            }
            return false
        case AylaPropertyBaseTypeInteger:
            if let intValue = Int(str!) {
                return true
            }
            return false
        case AylaPropertyBaseTypeDecimal:
            if let doubleValue = Double(str!) {
                return true
            }
            return false
        default:
            return false
        }
    }
    
    func keyboardTypeForPropertyBaseType(baseType: String?) -> UIKeyboardType! {
        // Return a keyboard type appropriate for the given property baseType
        if baseType == nil {
            return UIKeyboardType.Default
        }
        switch baseType!{
        case AylaPropertyBaseTypeString:
            return UIKeyboardType.Default
        case AylaPropertyBaseTypeBoolean:
            return UIKeyboardType.NumberPad
        case AylaPropertyBaseTypeInteger:
            return UIKeyboardType.NumberPad
        case AylaPropertyBaseTypeDecimal:
            return UIKeyboardType.DecimalPad
        default:
            return UIKeyboardType.Default
        }
    }
    
    // MARK: - UIPickerView Delegate
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.propertyPicker:
            return properties.count
        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case self.propertyPicker:
            let property = properties[row]
            propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
            self.selectedProperty = properties[row]
        default:
            break
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case self.propertyPicker:
            return propertyNames[row]
        default:
            return nil
        }
    }
    
}