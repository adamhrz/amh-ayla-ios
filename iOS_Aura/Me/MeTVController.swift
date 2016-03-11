//
//  MeTVController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/25/16.
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
        sessionManager = AylaCoreManager.sharedManager().getSessionManagerWithName(AuraSessionOneName)
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
