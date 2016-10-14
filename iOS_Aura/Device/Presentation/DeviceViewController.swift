//
//  DeviceViewController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceViewController: UIViewController, PropertyListViewModelDelegate, PropertyModelDelegate, DeviceSharesModelDelegate, TimeZonePickerViewControllerDelegate {

    @IBOutlet weak var panelView: DevicePanelView!
    @IBOutlet weak var tableView: UITableView!
    
    /// Segue id to property view
    let segueIdToPropertyView: String = "toPropertyView"
    
    /// Segue id to test view
    let segueIdToLanTestView: String = "toLanModeTest"
    
    /// Segue id to test view
    let segueIdToNetworkProfilerView: String = "toNetworkProfiler"
    
    /// Segue id to schedules view
    let segueIdToSchedules: String = "toSchedules"

    /// Segue id to notifications view
    let segueIdToNotifications: String = "toNotifications"

    /// Segue id to time zone picker
    let segueIdToTimeZonePicker = "toTimeZonePicker"
    
    /// Device which is represented on this device view.
    var device :AylaDevice?
    
    /// Device model used by view controller to present this device.
    var deviceViewModel :DeviceViewModel?
    
    var sharesModel: DeviceSharesModel?
    
    var nameTextField :UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let device = self.device {
            // Allocate a device view model to handle UX of panel view and table view.
            deviceViewModel = DeviceViewModel(device: device, panel: panelView, propertyListTableView: tableView, sharesModel:sharesModel)
            deviceViewModel?.propertyListViewModel?.delegate = self
            
            let options = UIBarButtonItem(barButtonSystemItem:.Action, target: self, action: #selector(DeviceViewController.showOptions))
            sharesModel?.delegate = self
            
            self.navigationItem.rightBarButtonItem = options
        }
        else {
            print("- WARNING - a device view with no device")
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.deviceViewModel!.update()
    }
    
    @IBAction func fetchAllPropertiesAction(sender: AnyObject) {
        self.device?.fetchPropertiesCloud(nil, success: { (properties) in
            print("Fetched properties")
            }, failure: { (error) in
                UIAlertController.alert("Error", message: "Failed to fetch all properties", buttonTitle: "OK", fromController: self)
        })
    }
    
    func rename() {
        deviceViewModel?.renameDevice(self, successHandler: nil, failureHandler: nil)
    }
    
    func unregister() {
        deviceViewModel?.unregisterDeviceWithConfirmation(self, successHandler: { Void in
            self.navigationController?.popViewControllerAnimated(true)
            }, failureHandler: { (error) in

        })
    }
    
    func shareDevice() {
        deviceViewModel?.shareDevice(self, successHandler: { (share) in
            }, failureHandler: { (error) in
                
        })
    }
    
    func changeTimeZone() {
        self.device?.fetchTimeZoneWithSuccess({ (timeZone) in
            self.performSegueWithIdentifier(self.segueIdToTimeZonePicker, sender: timeZone.tzID)
            }, failure: { (error) in
                let alert = UIAlertController(title: "Failed to fetch Time Zone", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:nil)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    // MARK: - Options
    
    func showOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let schedules = UIAlertAction(title: "Schedules", style: .Default) { (action) in
            self.performSegueWithIdentifier(self.segueIdToSchedules, sender: nil)
        }
        let notifications = UIAlertAction(title: "Notifications", style: .Default) { (action) in
            self.performSegueWithIdentifier(self.segueIdToNotifications, sender: nil)
        }
        let testRunner = UIAlertAction(title: "TestRunner", style: .Default) { (action) in
            self.performSegueWithIdentifier(self.segueIdToLanTestView, sender: nil)
        }
        
        let networkProfiler = UIAlertAction(title: "Network Profiler", style: .Default) { (action) in
            self.performSegueWithIdentifier(self.segueIdToNetworkProfilerView, sender: nil)
        }
        let rename = UIAlertAction(title: "Rename", style: .Default) { (action) in
            self.rename()
        }
        let share = UIAlertAction(title: "Share", style: .Default) { (action) in
            self.shareDevice()
        }
        let timeZone = UIAlertAction(title: "Change Time Zone", style: .Default) { (action) in
            self.changeTimeZone()
        }
        let unregister = UIAlertAction(title: "Unregister", style: .Destructive) { (action) in
            self.unregister()
        }

        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in }
        alert.addAction(schedules)
        
        // Only present Notifications if we have at least one contact and the device has at least one property
        let contacts = ContactManager.sharedInstance.contacts ?? []
        let managedProperties = device?.managedPropertyNames() ?? []
        if !contacts.isEmpty && !managedProperties.isEmpty {
            alert.addAction(notifications)
        }
        
        alert.addAction(testRunner)
        alert.addAction(networkProfiler)
        alert.addAction(rename)
        alert.addAction(share)
        alert.addAction(timeZone)
        alert.addAction(cancel)
        alert.addAction(unregister)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - DeviceSharesModelDelegate
    
    func deviceSharesModel(model: DeviceSharesModel, ownedSharesListDidUpdate: ((shares: [AylaShare]) -> Void)?) {
        self.deviceViewModel?.update()
    }
    
    func deviceSharesModel(model: DeviceSharesModel, receivedSharesListDidUpdate: ((shares: [AylaShare]) -> Void)?) {
        self.deviceViewModel?.update()
    }
    
    // MARK: - PropertyListViewModelDelegate
    
    func propertyListViewModel(viewModel: PropertyListViewModel, didSelectProperty property: AylaProperty, assignedPropertyModel propertyModel: PropertyModel) {
        propertyModel.delegate = self
        propertyModel.presentActions(presentingViewController: self);
    }
    
    func propertyListViewModel(viewModel:PropertyListViewModel, displayPropertyDetails property:AylaProperty, assignedPropertyModel propertyModel:PropertyModel){
        propertyModel.delegate = self
        propertyModel.chosenAction(PropertyModelAction.Details)
    }

    // MARK: - PropertyModelDelegate
    
    func propertyModel(model: PropertyModel, didSelectAction action: PropertyModelAction) {
        switch (action) {
        case .Details:
            self.performSegueWithIdentifier(segueIdToPropertyView, sender: model)
            break
        }
    }
    
    // MARK: - TimeZonePickerViewControllerDelegate
    
    func timeZonePickerDidCancel(picker: TimeZonePickerViewController)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func timeZonePicker(picker: TimeZonePickerViewController, didSelectTimeZoneID timeZoneID:String) {
        self.device?.updateTimeZoneTo(timeZoneID,
                                      success: { (timeZone) in
                                        self.deviceViewModel?.update()
            },
                                      failure: { (error) in
                                        let alert = UIAlertController(title: "Failed to save Time Zone", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                                        let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:nil)
                                        alert.addAction(okAction)
                                        self.presentViewController(alert, animated: true, completion: nil)
        })
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdToPropertyView {
            let vc = segue.destinationViewController as! PropertyViewController
            vc.propertyModel = sender as? PropertyModel
        }
        else if segue.identifier == segueIdToLanTestView {
            let nvc = segue.destinationViewController as! UINavigationController
            let vc = nvc.viewControllers[0] as! TestPanelViewController
            vc.testModel = LanModeTestModel(testPanelVC: vc, deviceManager: device?.deviceManager, device: device)
        }
        else if segue.identifier ==  segueIdToNetworkProfilerView {
            let nvc = segue.destinationViewController as! UINavigationController
            let vc = nvc.viewControllers[0] as! TestPanelViewController
            vc.testModel = NetworkProfilerModel(testPanelVC: vc, device: device)
        }
        else if segue.identifier == segueIdToSchedules {
            let vc = segue.destinationViewController as! ScheduleTableViewController
            vc.device = device
        }
        else if segue.identifier == segueIdToNotifications {
            let vc = segue.destinationViewController as! NotificationsViewController
            vc.device = device
        }
        else if segue.identifier == segueIdToTimeZonePicker {
            let nvc = segue.destinationViewController as! UINavigationController
            let vc = nvc.viewControllers[0] as! TimeZonePickerViewController
            vc.timeZoneID = sender as? String
            vc.delegate = self
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
