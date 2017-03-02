//
//  PropertyNotificationDetailsViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK
import UIKit

protocol PropertyNotificationDetailsViewControllerDelegate: class {
    func propertyNotificationDetailsDidCancel(_ controller: PropertyNotificationDetailsViewController)
    func propertyNotificationDetailsDidSave(_ controller: PropertyNotificationDetailsViewController)
}

// MARK: -

class PropertyNotificationDetailsViewController: UITableViewController, PropertyNotificationDetailsContactTableViewCellDelegate, UIPickerViewDataSource {

    weak var delegate:PropertyNotificationDetailsViewControllerDelegate?

    var device: AylaDevice!

    /// The property trigger to edit, nil if a new one should be created.
    var propertyTrigger: AylaPropertyTrigger? {
        didSet {
            if propertyTrigger != nil {
                _ = propertyTrigger?.fetchApps({ (triggerApps) in
                    self.triggerApps = triggerApps
                    }, failure: { (error) in
                        UIAlertController.alert("Failed to fetch Trigger Apps", message: error.description, buttonTitle: "OK", fromController: self)
                        self.triggerApps = []
                })
            } else {
                triggerApps = []
            }
        }
    }
    
    fileprivate var triggerApps: [AylaPropertyTriggerApp] = [] {
        didSet {
            // reset contacts
            emailContacts = []
            pushContacts = []
            smsContacts = []
            
            // create our initial contact lists
            for triggerApp in triggerApps {
                if let contactID = triggerApp.contactId {
                    if let contact = ContactManager.sharedInstance.contactWithID(contactID) {
                        switch triggerApp.type {
                        case .email:
                            emailContacts.append(contact)
                        case .push:
                            pushContacts.append(contact)
                        case .SMS:
                            smsContacts.append(contact)
                        default:
                            // unsupported type
                            break
                        }
                    }
                }
            }
            
            // update the view
            tableView.reloadData()
        }
    }

    fileprivate let allContacts = ContactManager.sharedInstance.contacts
    fileprivate var emailContacts: [AylaContact] = []
    fileprivate var pushContacts: [AylaContact] = []
    fileprivate var smsContacts: [AylaContact] = []
    
    fileprivate lazy var propertyNames: [String] = self.device.managedPropertyNames() ?? []
    
    @IBOutlet fileprivate weak var notificationNameField: UITextField!
    @IBOutlet fileprivate weak var triggerCompareField: UITextField!

    @IBOutlet fileprivate weak var triggerTypeSegmentedControl: UISegmentedControl!
    @IBOutlet fileprivate weak var triggerCompareSegmentedControl: UISegmentedControl!
    
    @IBOutlet fileprivate weak var propertyPickerView: UIPickerView!

    fileprivate enum PropertyNotificationDetailsSection: Int {
        case name = 0, condition, contacts, count
    }

    fileprivate enum PropertyNotificationDetailsSectionConditionRow: Int {
        case when, has, compare, count
    }
    
    fileprivate enum PropertyNotificationDetailsTriggerTypeSegment: Int {
        case onChange = 0, compare, any, count
    }

    fileprivate enum PropertyNotificationDetailsTriggerCompareSegment: Int {
        case equal = 0, greaterThan, lessThan, greaterThanOrEqual, lessThanOrEqual, count
    }

    fileprivate enum PropertyNotificationDetailsPropertyPickerComponent: Int {
        case propertyName = 0, count
    }

    fileprivate let propertyNotificationDetailsContactCellReuseIdentifier = "PropertyNotificationDetailsContactCell"
    
    // TODO: present in UI for editing
    fileprivate let notficationMessage = "[[property_name]] [[property_value]]"

    override func viewDidLoad() {
        super.viewDidLoad()

        triggerTypeSegmentedControl.tintColor = UIColor.auraTintColor()
        triggerCompareSegmentedControl.tintColor = UIColor.auraTintColor()
        
        tableView.register(PropertyNotificationDetailsContactTableViewCell.nib, forCellReuseIdentifier: propertyNotificationDetailsContactCellReuseIdentifier)
        
        if (propertyTrigger != nil) {
            updateViewsFromPropertyTrigger(propertyTrigger!)
        }
    }

    // MARK: - Actions
    
    @IBAction fileprivate func cancel(_ sender: AnyObject) {
        delegate?.propertyNotificationDetailsDidCancel(self)
    }

    @IBAction fileprivate func save(_ sender: AnyObject) {
        let name = notificationNameField?.text ?? ""
        
        if name.isEmpty {
            UIAlertController.alert("Please name the notification", message: nil, buttonTitle: "OK", fromController: self)
            return
        }
        
        let property = device.getProperty(propertyNames[propertyPickerView.selectedRow(inComponent: PropertyNotificationDetailsPropertyPickerComponent.propertyName.rawValue)])
        
        if (property == nil) {
            UIAlertController.alert("You cannot create a notification without first selecting a property", message: nil, buttonTitle: "OK", fromController: self)
            return
        }
        
        let triggerTypeSegment = PropertyNotificationDetailsTriggerTypeSegment(rawValue: triggerTypeSegmentedControl.selectedSegmentIndex)!
        
        let trigger = AylaPropertyTrigger()
        
        trigger.deviceNickname = name
        trigger.active = true
        trigger.triggerType = triggerTypeForSegmentIndex(triggerTypeSegment)
        
        if triggerTypeSegment == .compare {
            let compareValue = triggerCompareField.text ?? ""
            
            if compareValue.isEmpty {
                UIAlertController.alert("Please provide a value for comparison or select a different type of condition", message: nil, buttonTitle: "OK", fromController: self)
                return
            }
            
            trigger.compareType = triggerCompareForSegmentIndex(PropertyNotificationDetailsTriggerCompareSegment(rawValue: triggerCompareSegmentedControl.selectedSegmentIndex)!)
            trigger.value = compareValue
        }
        
        _ = property?.createTrigger(trigger, success: { (createdTrigger) in
            self.createTriggerAppsForProperty(property!, trigger: createdTrigger)
            
            let notifyDelegateForSave = {
                self.delegate?.propertyNotificationDetailsDidSave(self)
            }
            
            // Delete the original trigger, if there was one
            if self.propertyTrigger != nil {
                _ = property?.delete(self.propertyTrigger!, success: {
                    self.propertyTrigger = nil
                    notifyDelegateForSave()
                    }, failure: { (error) in
                        print("Failed to delete orginal trigger: \(error.description)")
                        notifyDelegateForSave()
                })
            } else {
                notifyDelegateForSave()
            }
            }, failure: { (error) in
                UIAlertController.alert("Failed to create new trigger", message: error.description, buttonTitle: "OK", fromController: self)
        })
    }

    @IBAction fileprivate func triggerTypeChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }

    // MARK: - Utilities

    fileprivate func createTriggerAppsForProperty(_ property: AylaProperty, trigger: AylaPropertyTrigger) {
        
        for emailContact in emailContacts {
            let triggerApp = AylaPropertyTriggerApp()
            
            triggerApp.configure(asEmailfor: emailContact, message: notficationMessage, username: nil, template: nil)
            
            trigger.createApp(triggerApp, success: { (triggerApp) in
                // Nothing to do
                }, failure: { (error) in
                    print("failed to add emailTriggerApp: \(error.description)")
            })
        }
        
        for smsContact in smsContacts {
            let triggerApp = AylaPropertyTriggerApp()
            
            triggerApp.configureAsSMS(for: smsContact, message: notficationMessage)
            
            trigger.createApp(triggerApp, success: { (triggerApp) in
                // Nothing to do
                }, failure: { (error) in
                    print("failed to add smsTriggerApp: \(error.description)")
            })
        }
        
        // TODO: Add support for push
//        for pushContact in pushContacts {
//            let triggerApp = AylaPropertyTriggerApp()
//            
//            triggerApp.configureAsPushWithMessage(notificationMessage, registrationId: sessionManager, applicationId: <#T##String#>, pushSound: <#T##String#>, pushMetaData: <#T##String#>)
//        }
    }
    
    fileprivate func updateViewsFromPropertyTrigger (_ propertyTrigger: AylaPropertyTrigger) {
        notificationNameField.text = propertyTrigger.deviceNickname
        triggerCompareField.text = propertyTrigger.value 
        
        triggerTypeSegmentedControl.selectedSegmentIndex = segmentIndexForAylaPropertyTriggerType(propertyTrigger.triggerType).rawValue
        triggerCompareSegmentedControl.selectedSegmentIndex = segmentIndexForAylaPropertyTriggerCompare(propertyTrigger.compareType).rawValue
        
        let propertyName = propertyTrigger.property?.name
        
        if propertyName != nil {
            if let propertyIndex = propertyNames.index(of: propertyName!) {
                propertyPickerView.selectRow(propertyIndex, inComponent: PropertyNotificationDetailsPropertyPickerComponent.propertyName.rawValue, animated: true)
            }
        }
    }
    
    fileprivate func segmentIndexForAylaPropertyTriggerType(_ triggerType: AylaPropertyTriggerType) -> PropertyNotificationDetailsTriggerTypeSegment {
        var index: PropertyNotificationDetailsTriggerTypeSegment
        
        switch triggerType {
        case .always: index = .any
        case .compareAbsolute: index = .compare
        case .onChange: index = .onChange
        default: index = .onChange; assert(false, "Unexpected triggerType!")
        }
        
        return index
    }
    
    fileprivate func triggerTypeForSegmentIndex(_ index: PropertyNotificationDetailsTriggerTypeSegment) -> AylaPropertyTriggerType {
        var triggerType: AylaPropertyTriggerType
        
        switch index {
        case .any: triggerType = .always
        case .compare: triggerType = .compareAbsolute
        case .onChange: triggerType = .onChange
        default: triggerType = .unknown; assert(false, "Unexpected index!")
        }
        
        return triggerType
    }
    
    fileprivate func segmentIndexForAylaPropertyTriggerCompare(_ triggerCompare: AylaPropertyTriggerCompare) -> PropertyNotificationDetailsTriggerCompareSegment {
        var index: PropertyNotificationDetailsTriggerCompareSegment
        
        switch triggerCompare {
        case .equalTo: index = .equal
        case .greaterThan: index = .greaterThan
        case .greaterThanOrEqualTo: index = .greaterThanOrEqual
        case .lessThan: index = .lessThan
        case .lessThanOrEqualTo: index = .lessThanOrEqual
        default: index = .equal; assert(false, "Unexpected triggerCompare!")
        }
        
        return index
    }
    
    fileprivate func triggerCompareForSegmentIndex(_ index: PropertyNotificationDetailsTriggerCompareSegment) -> AylaPropertyTriggerCompare {
        var triggerCompare: AylaPropertyTriggerCompare
        
        switch index {
        case .equal: triggerCompare = .equalTo
        case .greaterThan: triggerCompare = .greaterThan
        case .greaterThanOrEqual: triggerCompare = .greaterThanOrEqualTo
        case .lessThan: triggerCompare = .lessThan
        case .lessThanOrEqual: triggerCompare = .lessThanOrEqualTo
        default: triggerCompare = .equalTo; assert(false, "Unexpected index!")
        }
        
        return triggerCompare
    }

    // MARK: - PropertyNotificationDetailsContactTableViewCellDelegate

    func enabledAppsForContact(_ contact: AylaContact) -> [AylaServiceAppType] {
        var enabledApps: [AylaServiceAppType] = []
        
        if emailContacts.contains(contact) {
            enabledApps.append(.email)
        }
        
        if pushContacts.contains(contact) {
            enabledApps.append(.push)
        }
        
        if smsContacts.contains(contact) {
            enabledApps.append(.SMS)
        }
        
        return enabledApps
    }
    
    func didToggleEmail(_ cell: PropertyNotificationDetailsContactTableViewCell) {
        if let contact = cell.contact {
            if (emailContacts.contains(contact)) {
                emailContacts.remove(at: emailContacts.index(of: contact)!)
            } else {
                emailContacts.append(contact)
            }
        }
    }
    
    func didTogglePush(_ cell: PropertyNotificationDetailsContactTableViewCell) {
        if let contact = cell.contact {
            if (pushContacts.contains(contact)) {
                pushContacts.remove(at: pushContacts.index(of: contact)!)
            } else {
                pushContacts.append(contact)
            }
        }
    }
    
    func didToggleSMS(_ cell: PropertyNotificationDetailsContactTableViewCell) {
        if let contact = cell.contact {
            if (smsContacts.contains(contact)) {
                smsContacts.remove(at: smsContacts.index(of: contact)!)
            } else {
                smsContacts.append(contact)
            }
        }
    }

    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        assert(pickerView == propertyPickerView, "Unexpected picker!")
        
        return PropertyNotificationDetailsPropertyPickerComponent.count.rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        assert(pickerView == propertyPickerView, "Unexpected picker!")

        var numRows = 0
        
        switch PropertyNotificationDetailsPropertyPickerComponent(rawValue: component)! {
        case .propertyName:
            numRows = propertyNames.count
        default:
            assert(false, "unexpected picker component!")
            break
        }
        
        return numRows
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        assert(pickerView == propertyPickerView, "Unexpected picker!")

        var title = ""
        
        switch PropertyNotificationDetailsPropertyPickerComponent(rawValue: component)! {
        case .propertyName:
            title = propertyNames[row]
        default:
            assert(false, "unexpected picker component!")
            break
        }
        
        return title
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows:Int = 0
        
        if let propertyNotificationDetailsSection = PropertyNotificationDetailsSection(rawValue: section) {
            switch propertyNotificationDetailsSection {
            case .contacts:
                if allContacts != nil {
                    numRows = allContacts!.count
                }
            default:
                numRows = super.tableView(tableView, numberOfRowsInSection: section)
            }
        }
        
        return numRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if let propertyNotificationDetailsSection = PropertyNotificationDetailsSection(rawValue: indexPath.section) {
            switch propertyNotificationDetailsSection {
            case .contacts:
                let contactCell = tableView.dequeueReusableCell(withIdentifier: propertyNotificationDetailsContactCellReuseIdentifier, for: indexPath) as! PropertyNotificationDetailsContactTableViewCell
                
                // Must set delegate before setting contact
                contactCell.delegate = self

                contactCell.contact = allContacts?[indexPath.row]
                
                cell = contactCell
                
            default:
                cell = super.tableView(tableView, cellForRowAt: indexPath)
            }
        }
        
        return cell
    }

    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let propertyNotificationDetailsSection = PropertyNotificationDetailsSection(rawValue: indexPath.section)
        
        if (propertyNotificationDetailsSection == .contacts) {
            return 44.0
        }
        
        if (propertyNotificationDetailsSection == .condition) {
            let conditionRow = PropertyNotificationDetailsSectionConditionRow(rawValue: indexPath.row)
            
            if (conditionRow == .compare) && (PropertyNotificationDetailsTriggerTypeSegment(rawValue: triggerTypeSegmentedControl.selectedSegmentIndex) != .compare) {
                return 0.0
            }
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    // Need to override this or we get out of index crashes with the dynamic section
    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 0
    }
}
