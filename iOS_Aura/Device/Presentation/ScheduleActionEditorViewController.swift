//
//  ScheduleActionEditorViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleActionEditorViewController: UIViewController, UITextFieldDelegate,  UIPickerViewDataSource, UIPickerViewDelegate{
    
    private var sessionManager : AylaSessionManager?
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var parentScheduleNameLabel: UILabel!
    @IBOutlet private weak var activeSwitch: UISwitch!
    @IBOutlet private weak var propertyPicker: UIPickerView!
    @IBOutlet private weak var propertyTextField: UITextField!
    @IBOutlet private weak var valueTextField: UITextField!
    @IBOutlet private weak var saveActionButton: AuraButton!
    @IBOutlet private weak var valueLineItem: UIStackView!
    @IBOutlet private weak var firePointSelector: UISegmentedControl!
    
    private var properties : [AylaProperty?] = []
    private var propertyNames : [String?] = []

    private var selectedProperty : AylaProperty? = nil {
        didSet{
            if let property = self.selectedProperty {
                valueTextField.keyboardType = keyboardTypeForPropertyBaseType(property.baseType)
            }
            valueLineItem.hidden = selectedProperty == nil ? true : false
        }
    }
    private var selectedValue : AnyObject?
    private var selectedFirePoint : AylaScheduleActionFirePoint?
    
    var action : AylaScheduleAction? = nil
    
    var schedule : AylaSchedule? = nil {
        didSet {
            // Once retrieved from the schedule, store all properties for which an action can be created
            var allProperties : [AylaProperty?] = []
            if schedule?.device?.properties != nil {
                allProperties = schedule!.device!.properties!.map { ($0.1 as! AylaProperty) }
            }
            if !allProperties.isEmpty {
                properties = allProperties.filter{ $0!.direction == AylaScheduleDirectionToDevice }.filter{ [AylaPropertyBaseTypeBoolean,
                    AylaPropertyBaseTypeString,
                    AylaPropertyBaseTypeInteger,
                    AylaPropertyBaseTypeDecimal].contains($0!.baseType) }.map{ $0 }
            }
            if !properties.isEmpty {
                propertyNames = properties.map{ $0!.name }
            }
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
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem:.Cancel, target: self, action:#selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
        
        propertyTextField.delegate = self
        valueTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        tap.cancelsTouchesInView = false

        view.addGestureRecognizer(tap)
        
        propertyTextField.inputView = UIView()
        propertyPicker.dataSource = self
        propertyPicker.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        populateUI()
    }
    
    private func populateUI() {
        // Populate UI elements based on properties of a received schedule action, if one exists
        if action != nil {
            titleLabel.text = "Edit Schedule Action"
            saveActionButton.titleLabel?.text = "Update Action"
            let propertyName = self.action?.name
            if let propertyNameIndex = self.properties.indexOf({ $0!.name == propertyName }) {
                propertyPicker.selectRow(propertyNameIndex, inComponent: 0, animated: true)
                if let property = properties[propertyNameIndex] {
                    propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
                    selectedProperty = property
                }
            }
            valueTextField.text = String(action!.value)
            firePointSelector.selectedSegmentIndex = Int(action!.firePoint.rawValue - 1)
            parentScheduleNameLabel.text = schedule?.displayName
            activeSwitch.on = action!.active
        } else {
            parentScheduleNameLabel.text = schedule?.displayName
            titleLabel.text = "Create Schedule Action"
            saveActionButton.titleLabel?.text = "Create Action"
            selectedFirePoint = AylaScheduleActionFirePoint(rawValue: UInt(firePointSelector.selectedSegmentIndex + 1))
        }
        firePointSelector.tintColor = UIColor.auraLeafGreenColor()
    }
    
    private func internalError(){
        UIAlertController.alert("Internal Error", message: "A problem has occurred.", buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
            self.cancel()
        })
    }
    
    @objc private func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc private func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    private func toggleViewVisibilityAnimated(view: UIView){
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.33) {
                view.hidden = !(view.hidden)
            }
        }
    }

    @IBAction private func propertyFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(propertyPicker)
        if selectedProperty == nil {
            if let property = properties[propertyPicker.selectedRowInComponent(0)] {
                selectedProperty = property
                propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
            } else {
                internalError()
            }
        }
    }

    @IBAction private func segmentedControlChanged(sender: UISegmentedControl){
        selectedFirePoint = AylaScheduleActionFirePoint(rawValue: UInt(sender.selectedSegmentIndex + 1))
    }
    
    // MARK: Schedule Handling Methods
    
    private func propertyAndBaseTypeStringForProperty(property: AylaProperty) -> String{
        return property.name + " (" + property.baseType + ")"
    }
    
    private func checkAllRequiredFields() -> Bool{
        // Verify that all required properties have a value set and show alerts for missing ones.
        var message : String? = nil
        if selectedProperty == nil {
            message = "You must select a property."
        } else if selectedValue == nil {
            message = "You must enter a valid value for the property."
        } else if selectedFirePoint == nil {
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
    
    @IBAction private func saveActionButtonPressed(sender: AnyObject) {
        // If an action is present try to update it, otherwise, create a new one.
        saveActionButton.enabled = false
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
    
    
    private func updateScheduleAction(action: AylaScheduleAction, successHandler: (() -> Void)?, failureHandler: ((error: NSError) -> Void)?){
        if self.action == nil {
            internalError()
        } else {
            // Make a copy of existing action
            let actionToUpdate : AylaScheduleAction = self.action!.copy() as! AylaScheduleAction
            
            // Pull settings from UI and change existing schedule action accordingly
            if let property = selectedProperty {
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

            if schedule != nil {
                schedule!.updateScheduleActions([actionToUpdate], success: { (action) in
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
            } else {
                internalError()
            }
        }
    }
    
    private func createNewScheduleAction(successHandler: (() -> Void)?, failureHandler: ((error: NSError) -> Void)?){
        if checkAllRequiredFields() == true {
            if let schedule = schedule, let value = selectedValue, property = selectedProperty{
                let newAction = AylaScheduleAction(name: property.name,
                                                   value:value,
                                                   baseType: property.baseType,
                                                   active: activeSwitch.on,
                                                   firePoint: selectedFirePoint!,
                                                   schedule: schedule)
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
            } else {
                internalError()
            }
        }
    }
    
    
    // MARK: Text Field Delegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == self.propertyTextField {
            toggleViewVisibilityAnimated(propertyPicker)
            if selectedProperty == nil {
                if let property = properties[propertyPicker.selectedRowInComponent(0)] {
                    selectedProperty = property
                    propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
                } else {
                    internalError()
                }
            }
            return false
        } else {
            
            return true
        }
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
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        if textField == self.valueTextField {
            if validateStringInputForProperty(textField.text, property: selectedProperty) == true {
                selectedValue = valueForStringAndProperty(textField.text, property: selectedProperty)
                return true
            } else {
                UIAlertController.alert("Invalid Value", message: "Invalid Value for selected property.", buttonTitle: "OK", fromController: self)
                return false
            }
        } else {
            return true
        }
    }
    
    private func valueForStringAndProperty(str:String?, property: AylaProperty?) -> AnyObject? {
        // Given a string, and a target baseType, return a valid action.value if possible, otherwise nil.
        if str == nil || property == nil{
            return nil
        } else {
            switch property!.baseType{
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
    }
    
    private func validateStringInputForProperty(str:String?, property: AylaProperty?) -> Bool {
        // Given a string, and a target baseType, return a boolean for whether the string is a valid action.value.
        if let property = property {
            switch property.baseType{
            case AylaPropertyBaseTypeString:
                return true;
            case AylaPropertyBaseTypeBoolean:
                if str == "1" || str == "0" {
                    return true
                }
                return false
            case AylaPropertyBaseTypeInteger:
                if Int(str!) != nil {
                    return true
                }
                return false
            case AylaPropertyBaseTypeDecimal:
                if Double(str!) != nil {
                    return true
                }
                return false
            default:
                return false
            }
        } else {
            return false
        }
    }
    
    private func keyboardTypeForPropertyBaseType(baseType: String?) -> UIKeyboardType! {
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
        case propertyPicker:
            return properties.count
        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case propertyPicker:
            if let property = properties[row] {
                propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
                selectedProperty = properties[row]
            }
        default:
            break
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case propertyPicker:
            return propertyNames[row]
        default:
            return nil
        }
    }
    
}