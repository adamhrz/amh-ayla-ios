//
//  PropertyNotificationDetailsViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK
import UIKit

protocol PropertyNotificationDetailsViewControllerDelegate: class {
    func propertyNotificationDetailsDidCancel(controller: PropertyNotificationDetailsViewController)
    func propertyNotificationDetailsDidSave(controller: PropertyNotificationDetailsViewController)
}

// MARK: -

class PropertyNotificationDetailsViewController: UITableViewController, PropertyNotificationDetailsContactTableViewCellDelegate, UIPickerViewDataSource {

    weak var delegate:PropertyNotificationDetailsViewControllerDelegate?

    var device: AylaDevice!

    /// The property trigger to edit, nil if a new one should be created.
    var propertyTrigger: AylaPropertyTrigger? {
        didSet {
            if propertyTrigger != nil {
                propertyTrigger?.fetchApps({ (triggerApps) in
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
    
    private var triggerApps: [AylaPropertyTriggerApp] = [] {
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
                        case .Email:
                            emailContacts.append(contact)
                        case .Push:
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

    private let allContacts = ContactManager.sharedInstance.contacts
    private var emailContacts: [AylaContact] = []
    private var pushContacts: [AylaContact] = []
    private var smsContacts: [AylaContact] = []
    
    private lazy var propertyNames: [String] = self.device.managedPropertyNames() ?? []
    
    @IBOutlet private weak var notificationNameField: UITextField!
    @IBOutlet private weak var triggerCompareField: UITextField!

    @IBOutlet private weak var triggerTypeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var triggerCompareSegmentedControl: UISegmentedControl!
    
    @IBOutlet private weak var propertyPickerView: UIPickerView!

    private enum PropertyNotificationDetailsSection: Int {
        case Name = 0, Condition, Contacts, Count
    }

    private enum PropertyNotificationDetailsSectionConditionRow: Int {
        case When, Has, Compare, Count
    }
    
    private enum PropertyNotificationDetailsTriggerTypeSegment: Int {
        case OnChange = 0, Compare, Any, Count
    }

    private enum PropertyNotificationDetailsTriggerCompareSegment: Int {
        case Equal = 0, GreaterThan, LessThan, GreaterThanOrEqual, LessThanOrEqual, Count
    }

    private enum PropertyNotificationDetailsPropertyPickerComponent: Int {
        case PropertyName = 0, Count
    }

    private let propertyNotificationDetailsContactCellReuseIdentifier = "PropertyNotificationDetailsContactCell"
    
    // TODO: present in UI for editing
    private let notficationMessage = "[[property_name]] [[property_value]]"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerNib(PropertyNotificationDetailsContactTableViewCell.nib, forCellReuseIdentifier: propertyNotificationDetailsContactCellReuseIdentifier)
        
        if (propertyTrigger != nil) {
            updateViewsFromPropertyTrigger(propertyTrigger!)
        }
    }

    // MARK: - Actions
    
    @IBAction private func cancel(sender: AnyObject) {
        delegate?.propertyNotificationDetailsDidCancel(self)
    }

    @IBAction private func save(sender: AnyObject) {
        let name = notificationNameField?.text ?? ""
        
        if name.isEmpty {
            UIAlertController.alert("Please name the notification", message: nil, buttonTitle: "OK", fromController: self)
            return
        }
        
        let property = device.getProperty(propertyNames[propertyPickerView.selectedRowInComponent(PropertyNotificationDetailsPropertyPickerComponent.PropertyName.rawValue)])
        
        if (property == nil) {
            UIAlertController.alert("You cannot create a notification without first selecting a property", message: nil, buttonTitle: "OK", fromController: self)
            return
        }
        
        let triggerTypeSegment = PropertyNotificationDetailsTriggerTypeSegment(rawValue: triggerTypeSegmentedControl.selectedSegmentIndex)!
        
        let trigger = AylaPropertyTrigger()
        
        trigger.deviceNickname = name
        trigger.active = true
        trigger.triggerType = triggerTypeForSegmentIndex(triggerTypeSegment)
        
        if triggerTypeSegment == .Compare {
            let compareValue = triggerCompareField.text ?? ""
            
            if compareValue.isEmpty {
                UIAlertController.alert("Please provide a value for comparison or select a different type of condition", message: nil, buttonTitle: "OK", fromController: self)
                return
            }
            
            trigger.compareType = triggerCompareForSegmentIndex(PropertyNotificationDetailsTriggerCompareSegment(rawValue: triggerCompareSegmentedControl.selectedSegmentIndex)!)
            trigger.value = compareValue
        }
        
        property?.createTrigger(trigger, success: { (createdTrigger) in
            self.createTriggerAppsForProperty(property!, trigger: createdTrigger)
            
            // Delete the original trigger, if there was one
            if self.propertyTrigger != nil {
                property?.deleteTrigger(self.propertyTrigger!, success: {
                    self.propertyTrigger = nil
                    }, failure: { (error) in
                        print("Failed to delete orginal trigger: \(error.description)")
                })
            }
            
            self.delegate?.propertyNotificationDetailsDidSave(self)
            }, failure: { (error) in
                UIAlertController.alert("Failed to create new trigger", message: error.description, buttonTitle: "OK", fromController: self)
        })
    }

    @IBAction private func triggerTypeChanged(sender: UISegmentedControl) {
        tableView.reloadData()
    }

    // MARK: - Utilities

    private func createTriggerAppsForProperty(property: AylaProperty, trigger: AylaPropertyTrigger) {
        
        for emailContact in emailContacts {
            let triggerApp = AylaPropertyTriggerApp()
            
            triggerApp.configureAsEmailfor(emailContact, message: notficationMessage, username: nil, template: nil)
            
            trigger.createApp(triggerApp, success: { (triggerApp) in
                // Nothing to do
                }, failure: { (error) in
                    print("failed to add emailTriggerApp: \(error.description)")
            })
        }
        
        for smsContact in smsContacts {
            let triggerApp = AylaPropertyTriggerApp()
            
            triggerApp.configureAsSMSFor(smsContact, message: notficationMessage)
            
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
    
    private func updateViewsFromPropertyTrigger (propertyTrigger: AylaPropertyTrigger) {
        notificationNameField.text = propertyTrigger.deviceNickname
        triggerCompareField.text = propertyTrigger.value ?? ""
        
        triggerTypeSegmentedControl.selectedSegmentIndex = segmentIndexForAylaPropertyTriggerType(propertyTrigger.triggerType).rawValue
        triggerCompareSegmentedControl.selectedSegmentIndex = segmentIndexForAylaPropertyTriggerCompare(propertyTrigger.compareType).rawValue
        
        let propertyName = propertyTrigger.property?.name
        
        if propertyName != nil {
            if let propertyIndex = propertyNames.indexOf(propertyName!) {
                propertyPickerView.selectRow(propertyIndex, inComponent: PropertyNotificationDetailsPropertyPickerComponent.PropertyName.rawValue, animated: true)
            }
        }
    }
    
    private func segmentIndexForAylaPropertyTriggerType(triggerType: AylaPropertyTriggerType) -> PropertyNotificationDetailsTriggerTypeSegment {
        var index: PropertyNotificationDetailsTriggerTypeSegment
        
        switch triggerType {
        case .Always: index = .Any
        case .CompareAbsolute: index = .Compare
        case .OnChange: index = .OnChange
        default: index = .OnChange; assert(false, "Unexpected triggerType!")
        }
        
        return index
    }
    
    private func triggerTypeForSegmentIndex(index: PropertyNotificationDetailsTriggerTypeSegment) -> AylaPropertyTriggerType {
        var triggerType: AylaPropertyTriggerType
        
        switch index {
        case .Any: triggerType = .Always
        case .Compare: triggerType = .CompareAbsolute
        case .OnChange: triggerType = .OnChange
        default: triggerType = .Unknown; assert(false, "Unexpected index!")
        }
        
        return triggerType
    }
    
    private func segmentIndexForAylaPropertyTriggerCompare(triggerCompare: AylaPropertyTriggerCompare) -> PropertyNotificationDetailsTriggerCompareSegment {
        var index: PropertyNotificationDetailsTriggerCompareSegment
        
        switch triggerCompare {
        case .EqualTo: index = .Equal
        case .GreaterThan: index = .GreaterThan
        case .GreaterThanOrEqualTo: index = .GreaterThanOrEqual
        case .LessThan: index = .LessThan
        case .LessThanOrEqualTo: index = .LessThanOrEqual; assert(false, "Unexpected triggerCompare!")
        default: index = .Equal
        }
        
        return index
    }
    
    private func triggerCompareForSegmentIndex(index: PropertyNotificationDetailsTriggerCompareSegment) -> AylaPropertyTriggerCompare {
        var triggerCompare: AylaPropertyTriggerCompare
        
        switch index {
        case .Equal: triggerCompare = .EqualTo
        case .GreaterThan: triggerCompare = .GreaterThan
        case .GreaterThanOrEqual: triggerCompare = .GreaterThanOrEqualTo
        case .LessThan: triggerCompare = .LessThan
        case .LessThanOrEqual: triggerCompare = .LessThanOrEqualTo
        default: triggerCompare = .EqualTo; assert(false, "Unexpected index!")
        }
        
        return triggerCompare
    }

    // MARK: - PropertyNotificationDetailsContactTableViewCellDelegate

    func enabledAppsForContact(contact: AylaContact) -> [AylaServiceAppType] {
        var enabledApps: [AylaServiceAppType] = []
        
        if emailContacts.contains(contact) {
            enabledApps.append(.Email)
        }
        
        if pushContacts.contains(contact) {
            enabledApps.append(.Push)
        }
        
        if smsContacts.contains(contact) {
            enabledApps.append(.SMS)
        }
        
        return enabledApps
    }
    
    func didToggleEmail(cell: PropertyNotificationDetailsContactTableViewCell) {
        if let contact = cell.contact {
            if (emailContacts.contains(contact)) {
                emailContacts.removeAtIndex(emailContacts.indexOf(contact)!)
            } else {
                emailContacts.append(contact)
            }
        }
    }
    
    func didTogglePush(cell: PropertyNotificationDetailsContactTableViewCell) {
        if let contact = cell.contact {
            if (pushContacts.contains(contact)) {
                pushContacts.removeAtIndex(pushContacts.indexOf(contact)!)
            } else {
                pushContacts.append(contact)
            }
        }
    }
    
    func didToggleSMS(cell: PropertyNotificationDetailsContactTableViewCell) {
        if let contact = cell.contact {
            if (smsContacts.contains(contact)) {
                smsContacts.removeAtIndex(smsContacts.indexOf(contact)!)
            } else {
                smsContacts.append(contact)
            }
        }
    }

    // MARK: - UIPickerViewDataSource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        assert(pickerView == propertyPickerView, "Unexpected picker!")
        
        return PropertyNotificationDetailsPropertyPickerComponent.Count.rawValue
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        assert(pickerView == propertyPickerView, "Unexpected picker!")

        var numRows = 0
        
        switch PropertyNotificationDetailsPropertyPickerComponent(rawValue: component)! {
        case .PropertyName:
            numRows = propertyNames.count
        default:
            assert(false, "unexpected picker component!")
            break
        }
        
        return numRows
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        assert(pickerView == propertyPickerView, "Unexpected picker!")

        var title = ""
        
        switch PropertyNotificationDetailsPropertyPickerComponent(rawValue: component)! {
        case .PropertyName:
            title = propertyNames[row]
        default:
            assert(false, "unexpected picker component!")
            break
        }
        
        return title
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows:Int = 0
        
        if let propertyNotificationDetailsSection = PropertyNotificationDetailsSection(rawValue: section) {
            switch propertyNotificationDetailsSection {
            case .Contacts:
                if allContacts != nil {
                    numRows = allContacts!.count
                }
            default:
                numRows = super.tableView(tableView, numberOfRowsInSection: section)
            }
        }
        
        return numRows
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if let propertyNotificationDetailsSection = PropertyNotificationDetailsSection(rawValue: indexPath.section) {
            switch propertyNotificationDetailsSection {
            case .Contacts:
                let contactCell = tableView.dequeueReusableCellWithIdentifier(propertyNotificationDetailsContactCellReuseIdentifier, forIndexPath: indexPath) as! PropertyNotificationDetailsContactTableViewCell
                
                // Must set delegate before setting contact
                contactCell.delegate = self

                contactCell.contact = allContacts?[indexPath.row]
                
                cell = contactCell
                
            default:
                cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            }
        }
        
        return cell
    }

    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let propertyNotificationDetailsSection = PropertyNotificationDetailsSection(rawValue: indexPath.section)
        
        if (propertyNotificationDetailsSection == .Contacts) {
            return 44.0
        }
        
        if (propertyNotificationDetailsSection == .Condition) {
            let conditionRow = PropertyNotificationDetailsSectionConditionRow(rawValue: indexPath.row)
            
            if (conditionRow == .Compare) && (PropertyNotificationDetailsTriggerTypeSegment(rawValue: triggerTypeSegmentedControl.selectedSegmentIndex) != .Compare) {
                return 0.0
            }
        }
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    // Need to override this or we get out of index crashes with the dynamic section
    override func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        return 0
    }
}
