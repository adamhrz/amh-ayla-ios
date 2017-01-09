//
//  Aura
//
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import PDKeychainBindingsController
import SAMKeychain
import CoreTelephony

class AboutAuraTableViewController: UITableViewController {
    var user: AylaUser?
    let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)

    @IBOutlet weak var auraVersionLabel: UILabel!
    @IBOutlet weak var sdkVersionLabel: UILabel!
    @IBOutlet weak var configNameLabel: UILabel!
    
    
    @IBOutlet weak var phoneModelLabel: UILabel!
    @IBOutlet weak var iOSVersionLabel: UILabel!
    @IBOutlet weak var carrierNameLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    
    @IBOutlet weak var timeZoneLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionManager?.fetchUserProfile({ (user) in
            self.user = user
            
            }, failure: { (error) in
                print(error)
                UIAlertController.alert("Error", message: error.aylaServiceDescription, buttonTitle: "OK", fromController: self)
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        populateUI()
    }
    
    func populateUI() {
        let appVersion = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
        let carrier = CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName
        let deviceModel = self.getDeviceModel()
        let osVersion = UIDevice.currentDevice().systemVersion
        let country = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
        let language = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as! String
        
        let configName = AuraConfig.currentConfig().name
        
        let timeZone = NSTimeZone.localTimeZone().name
        
        auraVersionLabel.text = appVersion
        sdkVersionLabel.text = AYLA_SDK_VERSION
        configNameLabel.text = configName
        phoneModelLabel.text = deviceModel
        iOSVersionLabel.text = osVersion
        carrierNameLabel.text = carrier
        languageLabel.text = language
        countryLabel.text = country
        timeZoneLabel.text = timeZone
        
    }
    
    func getDeviceModel () -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafeMutablePointer(&systemInfo.machine) {
            ptr in String.fromCString(UnsafePointer<CChar>(ptr))
        }
        return modelCode
    }
    
    private func customOEMConfigs() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let developOptionsVC = storyboard.instantiateViewControllerWithIdentifier("DeveloperOptionsViewController") as! DeveloperOptionsViewController
        //let naviVC = UINavigationController(rootViewController: developOptionsVC)
        developOptionsVC.currentConfig = AuraConfig.currentConfig()
        self.navigationController?.pushViewController(developOptionsVC, animated: true)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let configIndexPath = NSIndexPath(forRow: 2, inSection: 0)
        if indexPath == configIndexPath {
            customOEMConfigs()
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
