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
        settings.serviceType = .Development
        settings.appId = "iMCA-Dev-0dfc7900-id"
        settings.appSecret = "iMCA-Dev-0dfc7900-5804184"

        // Set device detail provider
        settings.deviceDetailProvider = DeviceDetailProvider()
        
        // Set DSS as allowed
        settings.allowDSS = true;
        
        // Init device manager
        AylaCoreManager.initializeManagerWithSettings(settings)
        
        AylaLogManager.sharedManager().loggingLevel = .Info
        
        return true
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
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
            let setupVC2 = setupStoryboard.instantiateInitialViewController()
            self.window?.rootViewController?.presentViewController(setupVC2!, animated: true, completion:nil)
        }
        // If URL is from an Account Confirmation Email
        else if url.host == "user_sign_up_token" {
            
            // Pull Token from URL
            let tokenParam = queryitems?.filter({$0.name == "token"}).first;
            let token = tokenParam?.value;
            print("Will Confirm Sign Up with Token: \(token)")
            
            // Get LoginManager and send account confirmation token
            let loginManager = AylaCoreManager.sharedManager().loginManager
            loginManager.confirmAccountWithToken((token)!, success: { () -> Void in
                let alert = UIAlertController(title: "Account confirmed", message: "Enter your credentials to log in", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:nil)
                    alert.addAction(okAction)
                self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)

                }, failure: { (error) -> Void in
                    let alert = UIAlertController(title: "Account confirmation failed", message: "Something went wrong.  Account may already be confirmed.", preferredStyle: UIAlertControllerStyle.Alert)
                    let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:nil)
                    alert.addAction(okAction)
                    self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
            })

        }
        return true;
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        AylaCoreManager.sharedManager().pause()
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
        AylaCoreManager.sharedManager().resume()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

