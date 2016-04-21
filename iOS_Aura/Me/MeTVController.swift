//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import MessageUI
import UIKit
import iOS_AylaSDK

class MeTVController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    let sessionManager: AylaSessionManager?
    
    struct Selection {
        let myProfile = NSIndexPath(forRow: 0, inSection: 0)
        let emaiLogs = NSIndexPath(forRow: 0, inSection: 1)
        let logout = NSIndexPath(forRow: 0, inSection: 2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
        super.init(coder: aDecoder)
    }

    func logout() {
    
        if let manager = sessionManager {
            manager.logoutWithSuccess({ () -> Void in
                self.navigationController?.tabBarController?.dismissViewControllerAnimated(true, completion: { () -> Void in
                });
                }, failure: { (error) -> Void in
                    print("Log out operation failed: %@", error)
                    func alertWithLogout (message: String!, buttonTitle: String!){
                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                        let okAction = UIAlertAction (title: buttonTitle, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                            
                            self.navigationController?.tabBarController?.dismissViewControllerAnimated(true, completion: { () -> Void in
                            });
                        })
                        alert.addAction(okAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    switch error.code {
                    case AylaHTTPErrorCode.LostConnectivity.rawValue:
                        alertWithLogout("Your connection to the internet appears to be offline.  Could not log out properly.", buttonTitle: "Continue")
                    default:
                        alertWithLogout("An error has occurred", buttonTitle: "Continue")

                    }
            })
        }
    }
    
    func emailLogs() {
        let mailVC = MFMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            if let filePath = AylaLogManager.sharedManager().getLogFilePath() {
                let data = NSData(contentsOfFile: filePath)
                mailVC.setToRecipients([AylaNetworks.getSupportEmailAddress()])
                mailVC.setSubject("iOS SDK Log (\(AylaNetworks.getVersion()))")
                mailVC.setMessageBody("Add your feedback:", isHTML: false)
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selection = Selection()
        if(indexPath == selection.myProfile) {
            
        } else if (indexPath == selection.emaiLogs) {
            emailLogs()
        } else if (indexPath == selection.logout) {
            logout()
        }
        else {
            print("Unknown indexPath in `Me`")
        }
    }
    
    // MARK - MFMailComposeViewControllerDelegate
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
