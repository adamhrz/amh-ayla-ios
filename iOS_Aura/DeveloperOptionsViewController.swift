//
//  DeveloperOptionsViewController.swift
//  iOS_Aura
//
//  Created by Andy on 4/26/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import PDKeychainBindingsController
import SAMKeychain

class ConfigDetailCell: UITableViewCell {
    
    @IBOutlet private weak var appIdLabel: UILabel!
    @IBOutlet private weak var appSecretLabel: UILabel!
    @IBOutlet private weak var serviceTypeLabel: UILabel!
    @IBOutlet private weak var serviceLocationLabel: UILabel!
    @IBOutlet private weak var allowDSSLabel: UILabel!
    @IBOutlet private weak var allowOfflineLabel: UILabel!
    @IBOutlet private weak var networkTimeoutLabel: UILabel!
    
    func configCell(config: NSDictionary, showSecret: Bool) {
        appIdLabel.text = config["appId"] as? String
        if showSecret {
            appSecretLabel.text = config["appSecret"] as? String
        } else {
            appSecretLabel.text = "*********"
        }
        
        serviceTypeLabel.text = config["serviceType"] as? String
        serviceLocationLabel.text = config["serviceLocation"] as? String
        
        let settings = AylaSystemSettings.defaultSystemSettings()
        
        if let allowDSS = config["allowDSS"] as? Bool {
            allowDSSLabel.text = allowDSS ? "YES" : "NO"
        } else {
            allowDSSLabel.text = settings.allowDSS ? "YES" : "NO"
        }
        
        if let allowOfflineUse = config["allowOfflineUse"] as? Bool {
            allowOfflineLabel.text = allowOfflineUse ? "YES" : "NO"
        } else {
            allowOfflineLabel.text = settings.allowOfflineUse ? "YES" : "NO"
        }
        
        if let timeout = config["defaultNetworkTimeoutMs"] as? Int {
            networkTimeoutLabel.text = String(timeout)
        } else {
            networkTimeoutLabel.text = String(settings.defaultNetworkTimeout * 1000)
        }
    }
}

class DeveloperOptionsViewController: UITableViewController {
    
    private let IdentifyAvailableCell = "AvailableConfig"
    private let IdentifyConfigItemCell = "ConfigDetail"
    
    var currentConfig: AuraConfig! {
        didSet {
            if currentConfig.name == AuraConfig.ConfigNameStaging {
                easterEgg = true
            }
        }
    }

    private var currentConfigIndexPath: NSIndexPath!
    
    var easterEgg: Bool = false {
        didSet {
            if easterEgg == true {
                defaultConfigurations = AuraConfig.extendedDefaultConfigurations
                self.tableView.reloadData()
            }
        }
    }
    
    var fromLoginScreen: Bool = false
    var newConfigImport: Bool = false
    
    private var defaultConfigurations: [AuraConfig] = AuraConfig.defaultConfigurations
    
    private enum Section :Int {
        case Header
        case Defaults
        case Custom
        case Details
        case SectionCount
    }
    
    private var configURLList = [NSURL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.currentConfig == nil {
            self.currentConfig = AuraConfig.currentConfig()
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
        if let fileList = self.fetchConfigFileURLs() {
            configURLList = fileList
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
        if newConfigImport {
            let message = String(format:"New configuration '%@' has been imported.", self.currentConfig.name)
            UIAlertController.alert("Success", message: message, buttonTitle: "OK", fromController: self, okHandler: { (action) in
                let path = NSIndexPath(forRow: 0, inSection: Section.Custom.rawValue)
                self.tableView.scrollToRowAtIndexPath(path, atScrollPosition: .Top, animated: true)
            })
        }
    }
    
    private func fetchConfigFileURLs() -> [NSURL]? {
        let fileManager = NSFileManager.defaultManager()
        
        let paths = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = paths[0]
        
        do {
            let allContents = try fileManager.contentsOfDirectoryAtURL(documentsDirectory, includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants, .SkipsPackageDescendants])
            var filesOnly = [NSURL]()
            for item in allContents {
                var isDirectory : ObjCBool = ObjCBool(false)
                
                if fileManager.fileExistsAtPath(item.path!, isDirectory: &isDirectory) && isDirectory {
                    continue
                }
                filesOnly.append(item)
            }
            return filesOnly
        } catch _ {
            UIAlertController.alert("Error", message: "Could not read Documents directory", buttonTitle: "OK", fromController: self)
            return nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - DataSource & Delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.SectionCount.rawValue
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.Header.rawValue:
            return 0
        case Section.Defaults.rawValue:
            return self.defaultConfigurations.count
        case Section.Custom.rawValue:
            return configURLList.count
        case Section.Details.rawValue:
            return 1
        default:
            return 0
        }
        
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Section.Details.rawValue {
            return 217.0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Section.Details.rawValue {
            return 217.0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if indexPath.section == Section.Details.rawValue {
            cell = tableView.dequeueReusableCellWithIdentifier(IdentifyConfigItemCell)!
            (cell as! ConfigDetailCell).configCell(self.currentConfig.config, showSecret:easterEgg)
        } else if indexPath.section == Section.Defaults.rawValue {
            cell = tableView.dequeueReusableCellWithIdentifier(IdentifyAvailableCell)!
            let name = self.defaultConfigurations[indexPath.row].name
            cell.textLabel?.text = name
            if name == currentConfig.name {
                cell.accessoryType = .Checkmark
                currentConfigIndexPath = indexPath
            } else {
                cell.accessoryType = .None
            }
        } else if indexPath.section == Section.Custom.rawValue {
            cell = tableView.dequeueReusableCellWithIdentifier(IdentifyAvailableCell)!
            let url = configURLList[indexPath.row]
            cell.textLabel?.text = url.lastPathComponent
            if url.lastPathComponent == String(format:"%@.auraconfig", currentConfig.name) {
                cell.accessoryType = .Checkmark
                currentConfigIndexPath = indexPath
            } else {
                cell.accessoryType = .None
            }
        } else {
            cell = UITableViewCell()
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.Header.rawValue:
            return "Choose a configuration from the list below. Additional configurations may be added via email attachments or launching a local .auraconfig file with the Aura application."
        case Section.Defaults.rawValue:
            return "Default Configurations"
        case Section.Custom.rawValue:
            return "Saved Custom Configurations"
        case Section.Details.rawValue:
            return "Details"
        default:
            return nil
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == Section.Defaults.rawValue {
            self.currentConfig = self.defaultConfigurations[indexPath.row]
            tableView.reloadData()
        } else if indexPath.section == Section.Custom.rawValue {
            let url = configURLList[indexPath.row]
            if let config = (UIApplication.sharedApplication().delegate as? AppDelegate)?.loadConfigAtURL(url) {
                self.currentConfig = config
                tableView.reloadData()
            }
        }
        
        if self.currentConfig.name != AuraConfig.currentConfig().name {
            self.navigationItem.rightBarButtonItem?.enabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        switch indexPath.section {
        case Section.Custom.rawValue:
            return true
        default:
            return false
        }
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if indexPath == currentConfigIndexPath {
                UIAlertController.alert("Error.", message: "Can't delete the currently selected configuration.  Please pick another before deleting this one.", buttonTitle: "Ok", fromController: self)
            } else {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(configURLList[indexPath.row])
                } catch {
                    print("Failed to delete file")
                }
                
                configURLList.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }
    
    
    @IBAction private func savePressed(sender: AnyObject) {
        var message = "Please log in using an account for the configuration selected, or create a new account for this configuration."
        if !fromLoginScreen {
            message = "You will now be logged out.  " + message
        }
        
        let alert = UIAlertController(title:"New Configuration Selected.", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.saveConfigs()
        })
        let cancelAction = UIAlertAction (title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
        })
        alert.addAction(okAction)
        alert.addAction(cancelAction)

        self.presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction private func cancelPressed(sender: AnyObject) {
        if fromLoginScreen || newConfigImport {
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    private func saveConfigs() {
        let settings = AylaSystemSettings.defaultSystemSettings()
        let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
        
        if fromLoginScreen || newConfigImport {
            if let username = PDKeychainBindings.sharedKeychainBindings().stringForKey(AuraUsernameKeychainKey) {
                SAMKeychain.deletePasswordForService(settings.appId, account: username)
            }
            AuraConfig.saveConfig(self.currentConfig)
            self.currentConfig.applyTo(settings)
            AylaNetworks.initializeWithSettings(settings)
            self.dismissViewControllerAnimated(true, completion: nil)
            
        } else {
    
            // Apply after logging out.
            let username = PDKeychainBindings.sharedKeychainBindings().stringForKey(AuraUsernameKeychainKey)
            SAMKeychain.deletePasswordForService(settings.appId, account: username)
            
            if let manager = sessionManager {
                manager.shutDownWithSuccess({ () -> Void in
                    do {
                        try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username)
                    } catch _ {
                        print("Failed to remove cached authorization")
                    }
                    AuraConfig.saveConfig(self.currentConfig)
                    self.currentConfig.applyTo(settings)
                    AylaNetworks.initializeWithSettings(settings)
                    self.navigationController?.dismissViewControllerAnimated(true, completion: { () -> Void in
                    });
                    }, failure: { (error) -> Void in
                        print("Log out operation failed: %@", error)
                        func alertWithLogout (message: String!, buttonTitle: String!){
                            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                            let okAction = UIAlertAction (title: buttonTitle, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                do {
                                    try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username)
                                } catch _ {
                                    print("Failed to remove cached authorization")
                                }
                                AuraConfig.saveConfig(self.currentConfig)
                                self.currentConfig.applyTo(settings)
                                AylaNetworks.initializeWithSettings(settings)
                                self.navigationController?.dismissViewControllerAnimated(true, completion: { () -> Void in
                                });
                            })
                            alert.addAction(okAction)
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                        switch error.code {
                        case AylaHTTPErrorCode.LostConnectivity.rawValue:
                            alertWithLogout("Your connection to the internet appears to be offline.  Could not log out properly.", buttonTitle: "Continue")
                        default:
                            alertWithLogout("An error has occurred.\n" + (error.aylaServiceDescription), buttonTitle: "Continue")
                            
                        }
                })
            }
        }
    }

}
