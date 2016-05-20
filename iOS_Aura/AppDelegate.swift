//
//  AppDelegate.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // Setup core manager
        let settings = AylaSystemSettings.defaultSystemSettings()
        // Setup app id/secret
        setupAuraOptions(settings)

        // Set device detail provider
        settings.deviceDetailProvider = DeviceDetailProvider()
        
        // Set DSS as allowed
        settings.allowDSS = true;
        
        // Init device manager
        AylaNetworks.initializeWithSettings(settings)
        
        AylaLogManager.sharedManager().loggingLevel = .Info
        
        UITabBar.appearance().tintColor = UIColor.auraTintColor()
        UINavigationBar.appearance().tintColor = UIColor.auraTintColor()
        
        return true
    }
    
    func setupAuraOptions(settings: AylaSystemSettings) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let type = defaults.integerForKey(AuraOptions.KeyServiceType)
        if type == 0 { // 0 == AylaServiceType.Dynamic
            settings.serviceType = .Development
        }
        else {
            settings.serviceType = AylaServiceType(rawValue: UInt16(type)) ?? .Development
        }
        
        let location = defaults.integerForKey(AuraOptions.KeyServiceLocation)
        settings.serviceLocation = AylaServiceLocation(rawValue: UInt16(location)) ?? .US
        
        if settings.serviceLocation == .CN {
            settings.appId = AuraOptions.AppIdCN
            settings.appSecret = AuraOptions.AppSecretCN
        }
        else if settings.serviceLocation == .EU {
            settings.appId = AuraOptions.AppIdEU
            settings.appSecret = AuraOptions.AppSecretEU
        }
        else {
            settings.appId = AuraOptions.AppIdUS
            settings.appSecret = AuraOptions.AppSecretUS
        }
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        func displayViewController(controller: UIViewController){
            //  VC hierarchy is different if we are logged in than if we are not. 
            //  This will ensure the VC is displayed.
            if self.window?.rootViewController?.presentedViewController != nil {
                UIApplication.sharedApplication().keyWindow?.rootViewController?.presentedViewController?.presentViewController(controller,animated:true,completion:nil)
            }
            else {
                self.window?.rootViewController?.presentViewController(controller, animated: true, completion: nil)
            }
        }
        
        // Instantiate and display a UIAlertViewController as needed
        func presentAlertController(title: String?, message: String?, withOkayButton: Bool, withCancelButton: Bool, okayHandler: (() -> Void)?, cancelHandler: (() -> Void)?){
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            if withOkayButton {
                let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:{(action) -> Void in
                    if let okayHandler = okayHandler{
                        okayHandler()
                    }
                })
                alert.addAction(okAction)
                if withCancelButton {
                    let cancelAction = UIAlertAction (title: "Cancel", style: UIAlertActionStyle.Cancel, handler:{(action) -> Void in
                        if let cancelHandler = cancelHandler{
                            cancelHandler()
                        }
                    })
                    alert.addAction(cancelAction)
                }
                displayViewController(alert)
            }
        }
        
        // Parse URL app was launched with
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        let queryitems = components?.queryItems
        
        // If URL is sent from WI-Fi Setup Screen
        if url.host == "wifi_setup" {
            
            // Pull DSN from URL
            let dsnParam = queryitems?.filter({$0.name == "dsn"}).first
            let dsn = dsnParam?.value
            print("Will Setup Wi-Fi for DSN: \(dsn)")
            
            // Instantiate and Push SetupViewController
            let setupStoryboard: UIStoryboard = UIStoryboard(name: "Setup", bundle: nil)
            let setupVC = setupStoryboard.instantiateInitialViewController()
            displayViewController(setupVC!)
        }
        // If URL is from an Account Confirmation Email
        else if url.host == "user_sign_up_token" {
            
            // Pull Token from URL
            let tokenParam = queryitems?.filter({$0.name == "token"}).first;
            let token = tokenParam?.value;
            print("Will Confirm Sign Up with Token: \(token)")
            
            presentAlertController("Account Confirmation",
                                   message: "Would you like to confirm to this account?",
                                   withOkayButton: true,
                                   withCancelButton: true,
                                   okayHandler:{(action) -> Void in
                                    
                                    // Get LoginManager and send account confirmation token
                                    let loginManager = AylaNetworks.shared().loginManager
                                    loginManager.confirmAccountWithToken((token)!, success: { () -> Void in
                                        presentAlertController("Account Confirmed",
                                            message: "Enter your credentials to log in",
                                            withOkayButton: true,
                                            withCancelButton: false,
                                            okayHandler:nil,
                                            cancelHandler:nil)
                                        }, failure: { (error) -> Void in
                                            presentAlertController("Account Confirmation Failed.",
                                                message: "Account may already be confirmed. Try logging in.",
                                                withOkayButton: true,
                                                withCancelButton: false,
                                                okayHandler:nil,
                                                cancelHandler:nil)
                                    })
 
            },cancelHandler:nil)
           
        }
        else if url.host == "user_reset_password_token" {
            
            let tokenParam = queryitems?.filter({$0.name == "token"}).first;
            
            // Instantiate and Push PasswordResetViewController
            let setupStoryboard: UIStoryboard = UIStoryboard(name: "PasswordReset", bundle: nil)
            let passwordResetNavController = setupStoryboard.instantiateInitialViewController() as! UINavigationController
            let passwordResetController = passwordResetNavController.viewControllers.first! as! PasswordResetTableViewController
            passwordResetController.passwordResetToken = tokenParam!.value! as String
            displayViewController(passwordResetNavController)
            //NSNotificationCenter.defaultCenter().postNotificationName("PasswordReset", object: tokenParam?.value)
        }
        else {
            presentAlertController("Not Yet Implemented.",
                                        message: String.localizedStringWithFormat("Cannot currently parse url with %@ parameter", url.host!),
                                        withOkayButton: true,
                                        withCancelButton: false,
                                        okayHandler:nil,
                                        cancelHandler:nil)
        }
        return true
    }
    


    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        AylaNetworks.shared().pause()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AylaNetworks.shared().resume()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    }


}

