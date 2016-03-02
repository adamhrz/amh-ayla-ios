//
//  OAuthLoginViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 02/03/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class OAuthLoginViewController: UIViewController, UIActionSheetDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    var authType : AylaOAuthType!
    
    weak var mainLoginViewController : LoginViewController!
    
    override func viewDidAppear(animated: Bool) {
        if authType == nil {
            askForAuthType()
        }
    }
    
    func askForAuthType() {
        let menuSheet = UIAlertController(title: "Login with", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        menuSheet.addAction(UIAlertAction(title: "Facebook", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.authType = AylaOAuthType.Facebook
            self.startOAuth()
        }))
        menuSheet.addAction(UIAlertAction(title: "Google", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.authType = AylaOAuthType.Google
            self.startOAuth()
        }))
        self.showViewController(menuSheet, sender: self)
    }
    func startOAuth() {
        // Create auth provider with user input.
        let auth = AylaOAuthProvider(webView: self.webView, type: self.authType)
        
        let loginManager = AylaCoreManager.sharedManager().loginManager
        loginManager.loginWithAuthProvider(auth, sessionName: AuraSessionOneName, success: { (_, sessionManager) -> Void in
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                
                self.mainLoginViewController.performSegueWithIdentifier(self.mainLoginViewController.segueIdToMain, sender: sessionManager)
            })
            
            }, failure: { (error) -> Void in
                self.mainLoginViewController.presentError(error)
        })
    }
}
