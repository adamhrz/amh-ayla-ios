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
    
    @IBOutlet fileprivate weak var appIdLabel: UILabel!
    @IBOutlet fileprivate weak var appSecretLabel: UILabel!
    @IBOutlet fileprivate weak var serviceTypeLabel: UILabel!
    @IBOutlet fileprivate weak var serviceLocationLabel: UILabel!
    @IBOutlet fileprivate weak var allowDSSLabel: UILabel!
    @IBOutlet fileprivate weak var allowOfflineLabel: UILabel!
    @IBOutlet fileprivate weak var networkTimeoutLabel: UILabel!
    
    func configCell(_ config: NSDictionary, showSecret: Bool) {
        appIdLabel.text = config["appId"] as? String
        if showSecret {
            appSecretLabel.text = config["appSecret"] as? String
        } else {
            appSecretLabel.text = "*********"
        }
        
        serviceTypeLabel.text = config["serviceType"] as? String
        serviceLocationLabel.text = config["serviceLocation"] as? String
        
        let settings = AylaSystemSettings.default()
        
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
    
    fileprivate let IdentifyAvailableCell = "AvailableConfig"
    fileprivate let IdentifyConfigItemCell = "ConfigDetail"
    
    var currentConfig: AuraConfig! {
        didSet {
            if currentConfig.name == AuraConfig.ConfigNameStaging {
                easterEgg = true
            }
        }
    }

    fileprivate var currentConfigIndexPath: IndexPath!
    
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
    
    fileprivate var defaultConfigurations: [AuraConfig] = AuraConfig.defaultConfigurations
    
    fileprivate enum Section :Int {
        case header
        case defaults
        case custom
        case details
        case sectionCount
    }
    
    fileprivate var configURLList = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.currentConfig == nil {
            self.currentConfig = AuraConfig.currentConfig()
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        if let fileList = self.fetchConfigFileURLs() {
            configURLList = fileList
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
        if newConfigImport {
            let message = String(format:"New configuration '%@' has been imported.", self.currentConfig.name)
            UIAlertController.alert("Success", message: message, buttonTitle: "OK", fromController: self, okHandler: { (action) in
                let path = IndexPath(row: 0, section: Section.custom.rawValue)
                self.tableView.scrollToRow(at: path, at: .top, animated: true)
            })
        }
    }
    
    fileprivate func fetchConfigFileURLs() -> [URL]? {
        let fileManager = FileManager.default
        
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        do {
            let allContents = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
            var filesOnly = [URL]()
            for item in allContents {
                var isDirectory : ObjCBool = ObjCBool(false)
                
                if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) && isDirectory.boolValue {
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.sectionCount.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.header.rawValue:
            return 0
        case Section.defaults.rawValue:
            return self.defaultConfigurations.count
        case Section.custom.rawValue:
            return configURLList.count
        case Section.details.rawValue:
            return 1
        default:
            return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Section.details.rawValue {
            return 217.0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Section.details.rawValue {
            return 217.0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if indexPath.section == Section.details.rawValue {
            cell = tableView.dequeueReusableCell(withIdentifier: IdentifyConfigItemCell)!
            (cell as! ConfigDetailCell).configCell(self.currentConfig.config, showSecret:easterEgg)
        } else if indexPath.section == Section.defaults.rawValue {
            cell = tableView.dequeueReusableCell(withIdentifier: IdentifyAvailableCell)!
            let name = self.defaultConfigurations[indexPath.row].name
            cell.textLabel?.text = name
            if name == currentConfig.name {
                cell.accessoryType = .checkmark
                currentConfigIndexPath = indexPath
            } else {
                cell.accessoryType = .none
            }
        } else if indexPath.section == Section.custom.rawValue {
            cell = tableView.dequeueReusableCell(withIdentifier: IdentifyAvailableCell)!
            let url = configURLList[indexPath.row]
            cell.textLabel?.text = url.lastPathComponent
            if url.lastPathComponent == String(format:"%@.auraconfig", currentConfig.name) {
                cell.accessoryType = .checkmark
                currentConfigIndexPath = indexPath
            } else {
                cell.accessoryType = .none
            }
        } else {
            cell = UITableViewCell()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.header.rawValue:
            return "Choose a configuration from the list below. Additional configurations may be added via email attachments or launching a local .auraconfig file with the Aura application."
        case Section.defaults.rawValue:
            return "Default Configurations"
        case Section.custom.rawValue:
            return "Saved Custom Configurations"
        case Section.details.rawValue:
            return "Details"
        default:
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == Section.defaults.rawValue {
            self.currentConfig = self.defaultConfigurations[indexPath.row]
            tableView.reloadData()
        } else if indexPath.section == Section.custom.rawValue {
            let url = configURLList[indexPath.row]
            if let config = (UIApplication.shared.delegate as? AppDelegate)?.loadConfigAtURL(url) {
                self.currentConfig = config
                tableView.reloadData()
            }
        }
        
        if self.currentConfig.name != AuraConfig.currentConfig().name {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        switch indexPath.section {
        case Section.custom.rawValue:
            return true
        default:
            return false
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath == currentConfigIndexPath {
                UIAlertController.alert("Error.", message: "Can't delete the currently selected configuration.  Please pick another before deleting this one.", buttonTitle: "Ok", fromController: self)
            } else {
                do {
                    try FileManager.default.removeItem(at: configURLList[indexPath.row])
                } catch {
                    print("Failed to delete file")
                }
                
                configURLList.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    
    @IBAction fileprivate func savePressed(_ sender: AnyObject) {
        var message = "Please log in using an account for the configuration selected, or create a new account for this configuration."
        if !fromLoginScreen {
            message = "You will now be logged out.  " + message
        }
        
        let alert = UIAlertController(title:"New Configuration Selected.", message:message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.saveConfigs()
        })
        let cancelAction = UIAlertAction (title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
        })
        alert.addAction(okAction)
        alert.addAction(cancelAction)

        self.present(alert, animated: true, completion: nil)
    }

    @IBAction fileprivate func cancelPressed(_ sender: AnyObject) {
        if fromLoginScreen || newConfigImport {
            self.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    fileprivate func saveConfigs() {
        let settings = AylaSystemSettings.default()
        let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)
        
        if fromLoginScreen || newConfigImport {
            if let username = PDKeychainBindings.shared().string(forKey: AuraUsernameKeychainKey) {
                SAMKeychain.deletePassword(forService: settings.appId, account: username)
            }
            AuraConfig.saveConfig(self.currentConfig)
            self.currentConfig.applyTo(settings)
            AylaNetworks.initialize(with: settings)
            self.dismiss(animated: true, completion: nil)
            
        } else {
    
            // Apply after logging out.
            let username = PDKeychainBindings.shared().string(forKey: AuraUsernameKeychainKey)
            SAMKeychain.deletePassword(forService: settings.appId, account: username!)
            
            if let manager = sessionManager {
                manager.shutDown(success: { () -> Void in
                    do {
                        try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username!)
                    } catch _ {
                        print("Failed to remove cached authorization")
                    }
                    AuraConfig.saveConfig(self.currentConfig)
                    self.currentConfig.applyTo(settings)
                    AylaNetworks.initialize(with: settings)
                    self.navigationController?.dismiss(animated: true, completion: { () -> Void in
                    });
                    }, failure: { (error) -> Void in
                        print("Log out operation failed: %@", error)
                        func alertWithLogout (_ message: String!, buttonTitle: String!){
                            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
                            let okAction = UIAlertAction (title: buttonTitle, style: UIAlertActionStyle.default, handler: { (action) -> Void in
                                do {
                                    try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username!)
                                } catch _ {
                                    print("Failed to remove cached authorization")
                                }
                                AuraConfig.saveConfig(self.currentConfig)
                                self.currentConfig.applyTo(settings)
                                AylaNetworks.initialize(with: settings)
                                self.navigationController?.dismiss(animated: true, completion: { () -> Void in
                                });
                            })
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                        }
                        switch (error as NSError).code {
                        case AylaHTTPErrorCode.lostConnectivity.rawValue:
                            alertWithLogout("Your connection to the internet appears to be offline.  Could not log out properly.", buttonTitle: "Continue")
                        default:
                            alertWithLogout("An error has occurred.\n" + (error.aylaServiceDescription), buttonTitle: "Continue")
                            
                        }
                })
            }
        }
    }

}
