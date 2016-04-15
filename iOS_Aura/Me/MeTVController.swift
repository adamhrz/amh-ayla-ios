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
                    if error.code == 1002 {
                        alertWithLogout("Your connection to the internet appears to be offline.  Could not log out properly.", buttonTitle: "Continue")
                    }
                    else {
                        alertWithLogout("An unknown error has occurred", buttonTitle: "Continue")
                    }
            })
        }
    
    }
    
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
