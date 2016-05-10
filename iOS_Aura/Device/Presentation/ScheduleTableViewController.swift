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
    var device : AylaDevice!
    var schedules = [AylaSchedule]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.reloadSchedules()
    }
    
    func reloadSchedules() {
        // fetch schedules
        device.fetchAllSchedulesWithSuccess({ (schedules) in
            //assign schedules in case of success
            self.schedules = schedules
            
            //reload table view
            self.tableView.reloadData()
        }) { (error) in
            // display an alert in case of error
                UIAlertController.alert("Error", message: "Could not fetch schedules", buttonTitle: "OK", fromController: self)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("\(ScheduleTableViewController.self)", forIndexPath: indexPath)

        let schedule = schedules[indexPath.row]
        
        cell.textLabel?.text = "\(schedule.displayName ?? "") (\(schedule.name))"
        let startAt = "\(schedule.startTimeEachDay ?? "")"
        let endTimeEachDay = "\(schedule.endTimeEachDay ?? "No end time")"
        let startDate = "\(schedule.startDate ?? "immediately")"
        let endDate = "\(schedule.endDate ?? "indefinite")"
        let active = "\(schedule.active ? "Active" : "Inactive")"
        let utc = "\(schedule.utc ? "UTC" : "Non-UTC")"
        
        cell.detailTextLabel?.text = "\(startAt) - \(endTimeEachDay), \(startDate) - \(endDate), \(utc), \(active)"
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
