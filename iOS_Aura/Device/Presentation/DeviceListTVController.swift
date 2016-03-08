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
    let segueIdToDevice = "toDevicePage"
    
    /// The session manager which retains device manager of device list showing on this table view.
    var sessionManager :AylaSessionManager?
    
    /// View model used by view controller to present device list.
    var viewModel : DeviceListViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sessionManager = AylaCoreManager.sharedManager().getSessionManagerWithName(AuraSessionOneName)
        
        if (sessionManager != nil) {
            viewModel = DeviceListViewModel(deviceManager: sessionManager!.deviceManager, tableView: tableView)
            viewModel?.delegate = self
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Device list view delegate

    func deviceListViewModel(viewModel: DeviceListViewModel, didSelectDevice device: AylaDevice) {
        // Swith to device page
        self.performSegueWithIdentifier(segueIdToDevice, sender: device)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdToDevice { // To device page
            if let device = sender as? AylaDevice {
                let vc = segue.destinationViewController as! DeviceViewController
                vc.device = device
            }
        }
    }
    
}
