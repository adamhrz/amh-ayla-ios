//
//  NotificationsViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK
import UIKit

class NotificationsViewController: UIViewController, PropertyNotificationDetailsViewControllerDelegate {

    var device: AylaDevice!
    
    var propertyTriggers = [AylaPropertyTrigger]()

    @IBOutlet private weak var tableView: UITableView!
    
    private enum NotificationsViewControllerSection: Int {
        case NotificationsViewControllerSectionPropertyNotifications = 0, NotificationsViewControllerSectionCount
    }

    private let propertyNotificationCellReuseIdentifier = "PropertyNotificationCell"

    /// Segue id to property notification details view
    private let segueIdToPropertyNotificationDetails: String = "toPropertyNotificationDetails"

    override func viewDidLoad() {
        super.viewDidLoad()

        self.reloadTriggers()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdToPropertyNotificationDetails {
            let nvc = segue.destinationViewController as! UINavigationController
            let vc = nvc.viewControllers[0] as! PropertyNotificationDetailsViewController
            vc.device = device
            vc.propertyTrigger = sender as? AylaPropertyTrigger
            vc.delegate = self
        }
    }

    // MARK: - Actions
    
    @IBAction private func addNotification(sender: AnyObject) {
        self.performSegueWithIdentifier(segueIdToPropertyNotificationDetails, sender: nil)
    }

    // MARK: - Utilities
    
    func reloadTriggers() {
        let fetchTriggersGroup = dispatch_group_create()
        var fetchedPropertyTriggers = [AylaPropertyTrigger]()
        var fetchErrors = [NSError]()
        
        // Rebuild the array by getting the properties we care about and fetching all triggers attached to them
        if let properties = device.managedPropertyNames() {
            for propertyName in properties {
                if let property = device.getProperty(propertyName) {
                    dispatch_group_enter(fetchTriggersGroup)
                    property.fetchTriggersWithSuccess({ (triggers) in
                        fetchedPropertyTriggers += triggers
                        dispatch_group_leave(fetchTriggersGroup)
                    }) { (error) in
                        fetchErrors.append(error)
                        dispatch_group_leave(fetchTriggersGroup)
                    }
                }
            }
        }
        
        dispatch_group_notify(fetchTriggersGroup, dispatch_get_main_queue()) {
            if !fetchErrors.isEmpty {
                print("Failed to fetch \(fetchErrors.count) Property Triggers: \(fetchErrors)")
                UIAlertController.alert("Failed to fetch \(fetchErrors.count) Property Triggers", message: "First error: \(fetchErrors.first?.description)", buttonTitle: "OK", fromController: self)
            }
            
            // Now that all of the fetch requests have completed, update our table with the new data
            self.propertyTriggers = fetchedPropertyTriggers
            self.tableView.reloadData()
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NotificationsViewControllerSection.NotificationsViewControllerSectionCount.rawValue
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows:Int = 0
        
        if let notificationsSection = NotificationsViewControllerSection(rawValue: section) {
            switch notificationsSection {
            case .NotificationsViewControllerSectionPropertyNotifications:
                numRows = self.propertyTriggers.count
            default:
                assert(false, "Unexpected section!")
            }
        }
        
        return numRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if let notificationsSection = NotificationsViewControllerSection(rawValue: indexPath.section) {
            switch notificationsSection {
            case .NotificationsViewControllerSectionPropertyNotifications:
                cell = tableView.dequeueReusableCellWithIdentifier(propertyNotificationCellReuseIdentifier, forIndexPath: indexPath) as UITableViewCell
                cell.accessoryType = .DisclosureIndicator
                
                let trigger = propertyTriggers[indexPath.row]
                
                cell.textLabel?.text = trigger.deviceNickname
                
                var triggerDescription = ""
                switch trigger.triggerType {
                case .Always:
                    triggerDescription = "trigger on a new datapoint"
                case .CompareAbsolute:
                    let compareTypeName = AylaPropertyTrigger.comparisonNameFromType(trigger.compareType)
                    triggerDescription = "when value \(compareTypeName) \(trigger.value)"
                case .OnChange:
                    triggerDescription = "when a different value is set"
                case .Unknown:
                    triggerDescription = "unknown trigger type"
                }

                let triggerTypeName = AylaPropertyTrigger.triggerTypeNameFromType(trigger.triggerType)
                cell.detailTextLabel?.text = "\(trigger.propertyNickname) \(triggerTypeName) \(triggerDescription)"

            default:
                assert(false, "Unexpected section!")
            }
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let notificationsSection = NotificationsViewControllerSection(rawValue: indexPath.section) {
            switch notificationsSection {
            case .NotificationsViewControllerSectionPropertyNotifications:
                self.performSegueWithIdentifier(segueIdToPropertyNotificationDetails, sender: propertyTriggers[indexPath.row])
            default:
                assert(false, "Unexpected section!")
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var actions: [UITableViewRowAction] = []
        
        if let notificationsSection = NotificationsViewControllerSection(rawValue: indexPath.section) {
            switch notificationsSection {
            case .NotificationsViewControllerSectionPropertyNotifications:
                let deleteAction = UITableViewRowAction(style: .Destructive, title: "Delete") { (rowAction, indexPath) in
                    let trigger = self.propertyTriggers[indexPath.row]
                    
                    trigger.property?.deleteTrigger(trigger, success: {
                        if let index = self.propertyTriggers.indexOf(trigger) {
                            self.propertyTriggers.removeAtIndex(index)
                        } else {
                            assert(false, "failed to get the index of the trigger that was just deleted which should never happen!")
                        }
                        
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                        }, failure: { (error) in
                            UIAlertController.alert("Failed to delete trigger", message: error.description, buttonTitle: "OK", fromController: self)
                    })
                }

                actions.append(deleteAction)
            default:
                assert(false, "Unexpected section!")
            }
        }
        
        return actions
    }
    
    // MARK: - PropertyNotificationDetailsViewControllerDelegate
    
    func propertyNotificationDetailsDidCancel(controller: PropertyNotificationDetailsViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func propertyNotificationDetailsDidSave(controller: PropertyNotificationDetailsViewController){
        reloadTriggers()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
