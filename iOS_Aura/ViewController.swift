//
//  ViewController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let settings = AylaSystemSettings.defaultSystemSettings()
        settings.serviceType = .Development
        settings.appId = "iMCA-Dev-0dfc7900-id"
        settings.appSecret = "iMCA-Dev-0dfc7900-5804184"
        
        let manager = AylaCoreManager.initializeManagerWithSettings(settings)
        
        manager
        
        // Login
        let authProvicer = AylaUsernameAuthProvider(username: "yipeimail@gmail.com", password: "yptest")
        
        manager.loginManager.loginWithAuthProvider(authProvicer, sessionName: "sessionName", success: { (_, _) -> Void in
            
            }) { (err) -> Void in
                // Captured an error
                print(err)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

