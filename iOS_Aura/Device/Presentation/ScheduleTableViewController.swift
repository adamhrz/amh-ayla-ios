//
//  ScheduleTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 5/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class ScheduleTableViewController: UITableViewController {
    let segueToScheduleEditorId = "toScheduleEditor"
    let scheduleCellID = "ScheduleTableViewCell"
    
    var device : AylaDevice!
    var schedules = [AylaSchedule]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.refreshControl?.enabled = true
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh schedules")
        self.refreshControl?.addTarget(self, action: #selector(self.reloadSchedules), forControlEvents: .ValueChanged)    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadSchedules()
    }
    
    func reloadSchedules() {
        // fetch schedules
        device.fetchAllSchedulesWithSuccess({ (schedules) in
            //assign schedules in case of success
            self.schedules = schedules
            
            //reload table view
            self.tableView.reloadData()
            if self.refreshControl?.refreshing == true {
                self.refreshControl?.endRefreshing()
            }
        }) { (error) in
            if self.refreshControl?.refreshing == true {
                self.refreshControl?.endRefreshing()
            }
            // display an alert in case of error
            UIAlertController.alert("Failed to fetch schedules", message: error.description, buttonTitle: "OK", fromController: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.schedules.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.scheduleCellID, forIndexPath: indexPath) as! ScheduleTableViewCell
        let schedule = schedules[indexPath.row]
        cell.configure(schedule)
        return cell
    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let schedule = schedules[indexPath.row]
        self.performSegueWithIdentifier(segueToScheduleEditorId, sender: schedule)
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == segueToScheduleEditorId) {
            let schedule : AylaSchedule = (sender as? AylaSchedule)!
            let scheduleEditorController = segue.destinationViewController as! ScheduleEditorViewController
            scheduleEditorController.device = device
            scheduleEditorController.schedule = schedule
        }
    }

}
