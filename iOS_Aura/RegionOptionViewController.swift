//
//  RegionOptionViewController.swift
//  iOS_Aura
//
//  Created by Andy on 4/26/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class RegionOptionViewController: UITableViewController {
    
    let serviceLocations:[AylaServiceLocation] = [.US, .CN, .EU]
    let serviceTypes:[AylaServiceType] = [.Development, .Field, .Staging]
    
    var location: AylaServiceLocation = .US
    var service: AylaServiceType = .Development

    override func viewDidLoad() {
        super.viewDidLoad()

        let settings = AylaNetworks.shared().systemSettings
        location = settings.serviceLocation
        service = settings.serviceType
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - DataSource & Delegate
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {  // region
            if serviceLocations.indexOf(self.location) == indexPath.row {
                cell.accessoryType = .Checkmark
            }
            else {
                cell.accessoryType = .None
            }
        }
        else {  // service type
            if serviceTypes.indexOf(self.service) == indexPath.row {
                cell.accessoryType = .Checkmark
            }
            else {
                cell.accessoryType = .None
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            self.location = serviceLocations[indexPath.row]
        }
        else {
            self.service = serviceTypes[indexPath.row]
        }
        tableView.reloadData()
    }

    @IBAction func donePressed(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: {
            self.saveConfigs()
        })
    }

    func saveConfigs() {
        let settings = DeveloperOptionsUtil.systemSettingsWithLocation(self.location, service: self.service)
        AylaNetworks.initializeWithSettings(settings)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(Int(settings.serviceLocation.rawValue), forKey: AuraOptions.KeyServiceLocation)
        defaults.setInteger(Int(settings.serviceType.rawValue), forKey: AuraOptions.KeyServiceType)
    }
}
