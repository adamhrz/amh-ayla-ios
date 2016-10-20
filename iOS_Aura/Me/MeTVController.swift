//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import MessageUI
import UIKit
import iOS_AylaSDK
import PDKeychainBindingsController
import SAMKeychain
import CoreTelephony

class MeTVController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    let sessionManager: AylaSessionManager?
    
    enum Selection:Int {
        case myProfile = 0
        case emaiLogs
        case configurationWizard
        case logout
    }
    
    required init?(coder aDecoder: NSCoder) {
        sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
        super.init(coder: aDecoder)
    }

    func logout() {
        let settings = AylaNetworks.shared().systemSettings
        let username = PDKeychainBindings.sharedKeychainBindings().stringForKey(AuraUsernameKeychainKey)
        SAMKeychain.deletePasswordForService(settings.appId, account: username)
        if let manager = sessionManager {
            manager.shutDownWithSuccess({ () -> Void in
                do {
                    try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username)
                } catch _ {
                    print("Failed to remove cached authorization")
                }
                self.navigationController?.tabBarController?.dismissViewControllerAnimated(true, completion: { () -> Void in
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
                        alertWithLogout("An error has occurred.\n" + (error.aylaServiceDescription ?? ""), buttonTitle: "Continue")

                    }
            })
        }
    }
    
    func getDeviceModel () -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafeMutablePointer(&systemInfo.machine) {
            ptr in String.fromCString(UnsafePointer<CChar>(ptr))
        }
        return modelCode
    }
    func removeOptionalStrings(inputText :String) -> String {
        return inputText.stringByReplacingOccurrencesOfString("Optional(\"", withString: "").stringByReplacingOccurrencesOfString("\")", withString: "")
    }
    
    func emailLogs() {
        let mailVC = MFMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            if let filePath = AylaLogManager.sharedManager().getLogFilePath() {
                let data = NSData(contentsOfFile: filePath)
                mailVC.setToRecipients([AylaNetworks.getSupportEmailAddress()])
                mailVC.setSubject("iOS SDK Log (\(AylaNetworks.getVersion()))")
                
                let appVersion = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
                let carrier = CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName
                let deviceModel = self.getDeviceModel()
                let osVersion = UIDevice.currentDevice().systemVersion
                let country = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
                let language = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as! String
                
                var emailMessageBody = "Latest logs from Aura app attached\n\nDevice Model: \(deviceModel)\nOS Version: \(osVersion)\nCountry: \(country)\nLanguage: \(language)\nNetwork Operator: \(carrier)\nAyla SDK version: \(AYLA_SDK_VERSION)\nAura app version: \(appVersion)"
                emailMessageBody = self.removeOptionalStrings(emailMessageBody)
                mailVC.setMessageBody(emailMessageBody, isHTML: false)
                if data != nil {
                    mailVC.addAttachmentData(data!, mimeType: "application/plain", fileName: "sdk_log")
                }
                mailVC.mailComposeDelegate = self
                
                presentViewController(mailVC, animated: true, completion: nil)
            }
            else  {
                UIAlertController.alert(nil, message: "No log file found.", buttonTitle: "Got it", fromController: self)
            }
        }
        else  {
            UIAlertController.alert(nil, message: "Unable to send an email.", buttonTitle: "Got it", fromController: self)
        }
    }
    
    func customOEMConfigs() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let developOptionsVC = storyboard.instantiateViewControllerWithIdentifier("DeveloperOptionsViewController") as! DeveloperOptionsViewController
        //let naviVC = UINavigationController(rootViewController: developOptionsVC)
        developOptionsVC.currentConfig = AuraConfig.currentConfig()
        self.navigationController?.pushViewController(developOptionsVC, animated: true)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let selection = Selection(rawValue: indexPath.section)
            else {
                print("Unknown indexPath in `Me`")
                return
        }
        switch selection {
        case .myProfile:
            return
        case .configurationWizard:
            customOEMConfigs()
        case .emaiLogs:
            emailLogs()
        case .logout:
            logout()
        }
    }
    
    // MARK - MFMailComposeViewControllerDelegate
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
