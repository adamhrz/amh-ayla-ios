//
//  DeviceViewController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceViewController: UIViewController, PropertyListViewModelDelegate, PropertyModelDelegate {

    @IBOutlet weak var panelView: DevicePanelView!
    @IBOutlet weak var tableView: UITableView!
    
    /// Segue id to property view
    let segueIdToPropertyView: String = "toPropertyView"
    
    /// Device which is represented on this device view.
    var device :AylaDevice?
    
    /// Device model used by view controller to present this device.
    var deviceViewModel :DeviceViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let device = self.device {
            // Allocate a device view model to handle UX of panel view and table view.
            deviceViewModel = DeviceViewModel(device: device, panel: panelView, propertyListTableView: tableView)
            deviceViewModel?.propertyListViewModel?.delegate = self
        }
        else {
            print("- WARNING - a device view with no device")
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    // MARK - Property list view model delegate
    func propertyListViewModel(viewModel: PropertyListViewModel, didSelectProperty property: AylaProperty, assignedPropertyModel propertyModel: PropertyModel) {
        propertyModel.delegate = self
        propertyModel.presentActions(presentingViewController: self);
    }
    
    // MARK - Property model delegate
    func propertyModel(model: PropertyModel, didSelectAction action: PropertyModelAction) {
        switch (action) {
        case .Details:
            self.performSegueWithIdentifier(segueIdToPropertyView, sender: model)
            break
        }
    }
    
    // MARK - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdToPropertyView {
            let vc = segue.destinationViewController as! PropertyViewController
            vc.propertyModel = sender as? PropertyModel
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
