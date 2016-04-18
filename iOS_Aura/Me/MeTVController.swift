//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class MeTVController: UITableViewController {
    
    let sessionManager: AylaSessionManager?
    
    struct Selection {
        let myProfile = NSIndexPath(forRow: 0, inSection: 0)
        let settings = NSIndexPath(forRow: 0, inSection: 1)
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
                    
            })
        }
    
    }
   /*
 
    @IBAction func deleteAccountAction(sender:AnyObject){
        let alert = UIAlertController(title: "Delete Account?", message: "Deleting your account is permanent and cannot be undone.  All devices registered to you must also be unregistered.  The process may take some time to complete. Are you sure you want to continue?", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:{(action) -> Void in
            self.deleteAccount({ 
                self.logout()
            }, failure: {
                    <#code#>
            })
        })
        alert.addAction(okAction)
        let cancelAction = UIAlertAction (title: "Cancel", style: UIAlertActionStyle.Cancel, handler:{(action) -> Void in })
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
        
    }

    
    func deleteAccount(success: (() -> Void)?, failure: (() -> Void)?){
        if let manager = sessionManager {
            manager.deleteAccountWithSuccess({ 
                if let success = success{
                    success()
                }
            }, failure: {(NSError) -> Void in
                if let failure = failure {
                    failure()
                }
                    
            })
        }

    }
 */
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selection = Selection()
        if(indexPath == selection.myProfile) {
            
        } else if (indexPath == selection.settings) {
        
        } else if (indexPath == selection.logout) {
            logout()
        }
        else {
            print("Unknown indexPath in `Me`")
        }
    }
    
}
