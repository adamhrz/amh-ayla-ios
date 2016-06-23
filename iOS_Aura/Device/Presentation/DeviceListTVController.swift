//
//  DeviceListTVController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceListTVController: UITableViewController, DeviceListViewModelDelegate {

    /// Id of a segue which is linked to device page.
    let segueIdToDevice :String = "toDevicePage"
    
    /// Segue id to property view
    let segueIdToRegisterView :String = "toRegisterPage"
    
    /// Segue id to Shares List view
    let segueIdToSharesView :String = "toSharesPage"
    
    /// The session manager which retains device manager of device list showing on this table view.
    var sessionManager :AylaSessionManager?
    
    /// View model used by view controller to present device list.
    var viewModel : DeviceListViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
        
        if let sessionManager = sessionManager {
            viewModel = DeviceListViewModel(deviceManager: sessionManager.deviceManager, tableView: tableView)
            viewModel?.delegate = self
            if sessionManager.cachedSession {
                UIAlertController.alert("Offline Mode", message: "Logged in LAN Mode, some features might not be available", buttonTitle: "OK", fromController: self)
            }
        }
        else {
            print(" - WARNING - device list with a nil session manager")
            // TODO: present a warning and give fresh option
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    @IBAction func rightBarButtonTapped(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Register a Device", style: .Default, handler: { (action) -> Void in
            self.performSegueWithIdentifier(self.segueIdToRegisterView, sender: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Wi-Fi Setup", style: .Default, handler: { (action) -> Void in
            let setupStoryboard: UIStoryboard = UIStoryboard(name: "Setup", bundle: nil)
            let setupVC = setupStoryboard.instantiateInitialViewController()
            self.navigationController?.presentViewController(setupVC!, animated: true, completion:nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "View Device Shares", style: .Default, handler: { (action) -> Void in
            self.performSegueWithIdentifier(self.segueIdToSharesView, sender: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Device list view delegate

    func deviceListViewModel(viewModel: DeviceListViewModel, didSelectDevice device: AylaDevice) {
        // Swith to device page
        self.performSegueWithIdentifier(segueIdToDevice, sender: device)
    }
    
    func deviceListViewModel(viewModel: DeviceListViewModel, didUnregisterDevice device: AylaDevice){
        let deviceViewModel = DeviceViewModel(device: device, panel: nil, propertyListTableView: nil, sharesModel: self.viewModel!.sharesModel)
        deviceViewModel.unregisterDevice(self, successHandler: {
            self.tableView.reloadData()
            }, failureHandler: { (error) in
                self.tableView.reloadData()
        })
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdToDevice { // To device page
            if let device = sender as? AylaDevice {
                let vc = segue.destinationViewController as! DeviceViewController
                vc.device = device
                vc.sharesModel = self.viewModel?.sharesModel
            }
        } else if segue.identifier == segueIdToRegisterView { // To registration page
        }
    }
    
}
