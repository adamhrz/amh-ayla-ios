//
//  OAuthLoginViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 02/03/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import WebKit

class OAuthLoginViewController: UIViewController, UIActionSheetDelegate {

    @IBOutlet weak var webView: WKWebView!
    
    var authType : AylaOAuthType!
    
    weak var mainLoginViewController : LoginViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(cancelAuth))
        
        // WKWebView cannot be added through storyboards as of today. If possible in the future, this view could be added in the storyboard
        let webView = WKWebView()
        self.webView = webView
        self.view.addSubview(self.webView)
        self.webView.translatesAutoresizingMaskIntoConstraints = false;
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[webView]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: ["webView" : self.webView]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[webView]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: ["webView" : self.webView]))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidDisappear(animated)
        if authType == nil {
            askForAuthType()
        } else {
            self.startOAuth()
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
        menuSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.cancelAuth()
        }))
        self.presentViewController(menuSheet, animated: true, completion: nil)
    }
    
    func cancelAuth() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func startOAuth() {
        // Create auth provider with the webView and selected provider
        let auth = AylaOAuthProvider(webView: self.webView, type: self.authType)
        
        let loginManager = AylaNetworks.shared().loginManager
        loginManager.loginWithAuthProvider(auth, sessionName: AuraSessionOneName, success: { (_, sessionManager) -> Void in
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                
                self.mainLoginViewController.performSegueWithIdentifier(self.mainLoginViewController.segueIdToMain, sender: sessionManager)
            })
            
            }, failure: { (error) -> Void in
                self.mainLoginViewController.presentError(error)
        })
    }
}
