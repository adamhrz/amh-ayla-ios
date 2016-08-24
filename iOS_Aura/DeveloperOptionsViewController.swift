//
//  DeveloperOptionsViewController.swift
//  iOS_Aura
//
//  Created by Andy on 4/26/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class ConfigDetailCell: UITableViewCell {
    
    @IBOutlet weak var appIdLabel: UILabel!
    @IBOutlet weak var appSecretLabel: UILabel!
    @IBOutlet weak var serviceTypeLabel: UILabel!
    @IBOutlet weak var serviceLocationLabel: UILabel!
    @IBOutlet weak var allowDSSLabel: UILabel!
    @IBOutlet weak var allowOfflineLabel: UILabel!
    @IBOutlet weak var networkTimeoutLabel: UILabel!
    
    func configCell(config: NSDictionary) {
        appIdLabel.text = config["appId"] as? String
        appSecretLabel.text = config["appSecret"] as? String
        serviceTypeLabel.text = config["serviceType"] as? String
        serviceLocationLabel.text = config["serviceLocation"] as? String
        
        let settings = AylaSystemSettings.defaultSystemSettings()
        
        if let allowDSS = config["allowDSS"] as? Bool {
            allowDSSLabel.text = allowDSS ? "YES" : "NO"
        }
        else {
            allowDSSLabel.text = settings.allowDSS ? "YES" : "NO"
        }
        
        if let allowOfflineUse = config["allowOfflineUse"] as? Bool {
            allowOfflineLabel.text = allowOfflineUse ? "YES" : "NO"
        }
        else {
            allowOfflineLabel.text = settings.allowOfflineUse ? "YES" : "NO"
        }
        
        if let timeout = config["defaultNetworkTimeoutMs"] as? Int {
            networkTimeoutLabel.text = String(timeout)
        }
        else {
            networkTimeoutLabel.text = String(settings.defaultNetworkTimeout * 1000)
        }
    }
}

class DeveloperOptionsViewController: UITableViewController {
    
    let IdentifyAvailibaleCell = "AvailableConfig"
    let IdentifyConfigItemCell = "ConfigDetail"
    
    var currentConfig: AuraConfig!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.currentConfig == nil {
            self.currentConfig = AuraConfig.currentConfig()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - DataSource & Delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return AuraConfig.availableConfigurations.count
        }
        else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 217.0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 217.0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier(IdentifyAvailibaleCell)!
            cell.textLabel?.text = AuraConfig.availableConfigurations[indexPath.row].name
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier(IdentifyConfigItemCell)!
            (cell as! ConfigDetailCell).configCell(self.currentConfig.config)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Choose a configuration from the list below. Additional configurations may be added via email attachments or launching a local .auraconfig file with the Aura application."
        }
        
        return "Details"
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if AuraConfig.availableConfigurations[indexPath.row].name == currentConfig.name {
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
            self.currentConfig = AuraConfig.availableConfigurations[indexPath.row]
            tableView.reloadData()
        }
    }

    @IBAction func donePressed(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: {
            self.saveConfigs()
        })
    }

    @IBAction func cancelPressed(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func saveConfigs() {
        AuraConfig.saveConfig(currentConfig)
        
        // apply
        let settings = AylaSystemSettings.defaultSystemSettings()
        self.currentConfig.applyTo(settings)
        AylaNetworks.initializeWithSettings(settings)
    }
}
