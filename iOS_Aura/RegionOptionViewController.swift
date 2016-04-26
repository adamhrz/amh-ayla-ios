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
    
    let settings = AylaNetworks.shared().systemSettings
    
    let serviceLocations:[AylaServiceLocation] = [.US, .CN, .EU]
    let serviceTypes:[AylaServiceType] = [.Development, .Field, .Staging]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - DataSource & Delegate
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {  // region
            if serviceLocations.indexOf(settings.serviceLocation) == indexPath.row {
                cell.accessoryType = .Checkmark
            }
            else {
                cell.accessoryType = .None
            }
        }
        else {  // service type
            if serviceTypes.indexOf(settings.serviceType) == indexPath.row {
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
            settings.serviceLocation = serviceLocations[indexPath.row]
        }
        else {
            settings.serviceType = serviceTypes[indexPath.row]
        }
        tableView.reloadData()
    }

    @IBAction func donePressed(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: {
            self.saveConfigs()
        })
    }

    func saveConfigs() {
        if self.settings.serviceLocation == .CN {
            self.settings.appId = AuraOptions.AppIdCN
            self.settings.appSecret = AuraOptions.AppSecretCN
        }
        else { // TODO: No EU app id yet
            self.settings.appId = AuraOptions.AppIdUS
            self.settings.appSecret = AuraOptions.AppSecretUS
        }
        AylaNetworks.initializeWithSettings(self.settings)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(Int(self.settings.serviceLocation.rawValue), forKey: AuraOptions.KeyServiceLocation)
        defaults.setInteger(Int(self.settings.serviceType.rawValue), forKey: AuraOptions.KeyServiceType)
    }
}
