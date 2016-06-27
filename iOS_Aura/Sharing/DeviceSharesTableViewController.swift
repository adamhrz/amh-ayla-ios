//
//  DeviceSharesTableViewController.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/3/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceSharesTableViewController: UITableViewController, DeviceSharesModelDelegate, DeviceSharesListViewModelDelegate {
    
    /// The current session manager which retains the device manager.
    var sessionManager :AylaSessionManager?
    
    /// View model used by view controller to present device shares list.
    var viewModel : DeviceSharesListViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
        
        if (sessionManager != nil) {
            viewModel = DeviceSharesListViewModel(deviceManager: sessionManager!.deviceManager, tableView: tableView)
            viewModel?.delegate = self
            self.viewModel?.sharesModel?.delegate = self

        }
        else {
            print(" - WARNING - device list with a nil session manager")
            // TODO: present a warning and give fresh option
        }
        
        let cancel = UIBarButtonItem(barButtonSystemItem:.Cancel, target: self, action: #selector(DeviceSharesTableViewController.cancel))
        self.navigationItem.leftBarButtonItem = cancel
        self.navigationController?.navigationBar.translucent = false;
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh shares")
        self.refreshControl?.addTarget(self, action: #selector(DeviceSharesTableViewController.refreshShareData), forControlEvents: .ValueChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func cancel() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func reloadTableData(){
        self.tableView.reloadData()
    }
    
    func refreshShareData(){
        print("Manually Refreshing Share Data.")
        self.viewModel!.sharesModel!.updateSharesList({ (shares) in
            self.reloadTableData()
            self.refreshControl?.endRefreshing()
        }) { (error) in
            self.refreshControl?.endRefreshing()
            UIAlertController.alert("Failed to Refresh", message: error.description, buttonTitle: "OK", fromController: self)
        }
    }
    
    // MARK: - DeviceSharesListViewModelDelegate
    func deviceSharesListViewModel(viewModel:DeviceSharesListViewModel, didDeleteShare share:AylaShare) {
        let model = ShareViewModel(share: share)
        model.deleteShare(self, successHandler: {
            self.viewModel!.sharesModel?.updateSharesList({ (shares) in
                    self.reloadTableData()
                }, failureHandler: { (error) in
                    let alert = UIAlertController(title: "Failed to Update Shares List.", message: error.description, preferredStyle: .Alert)
                    let gotIt = UIAlertAction(title: "Got it", style: .Cancel, handler: nil)
                    alert.addAction(gotIt)
                    self.presentViewController(alert, animated: true, completion: nil)
                    self.reloadTableData()
            })
            }) { (error) in }
    }
    func deviceSharesListViewModel(viewModel:DeviceSharesListViewModel, didSelectShare share:AylaShare) {

    }
    
    // MARK: DeviceSharesModelDelegate
    func deviceSharesModel(model: DeviceSharesModel, ownedSharesListDidUpdate: ((shares: [AylaShare]) -> Void)?) {
        self.reloadTableData()
    }
    func deviceSharesModel(model: DeviceSharesModel, receivedSharesListDidUpdate: ((shares: [AylaShare]) -> Void)?) {
        self.reloadTableData()
    }
    
}
