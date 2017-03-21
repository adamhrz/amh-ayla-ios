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
    
    var auraSessionListener : AuraSessionListener?
    private let logTag = "AppDelegate"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if let url = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            if url.isFileURL {
                AylaLogI(tag: logTag, flag: 0, message:"Aura config file opened.")
            }
        }

        // Setup core manager
        let settings = AylaSystemSettings.default()
        
        // settings from AuraConfig
        AuraConfig.currentConfig().applyTo(settings)

        // Set device detail provider
        settings.deviceDetailProvider = DeviceDetailProvider()
        
        // Set DSS as allowed
        settings.allowDSS = false;
        
        // Uncomment following line to allow Offline use
        //settings.allowOfflineUse = true
        
        // Init device manager
        AylaNetworks.initialize(with: settings)
        
        let localDeviceManager = AuraLocalDeviceManager();
        AylaLogManager.shared().loggingLevel = .debug
        
        AylaNetworks.shared().installPlugin(localDeviceManager, id: PLUGIN_ID_DEVICE_CLASS)
        AylaNetworks.shared().installPlugin(localDeviceManager, id: AuraLocalDeviceManager.PLUGIN_ID_LOCAL_DEVICE)
        AylaNetworks.shared().installPlugin(localDeviceManager, id: PLUGIN_ID_DEVICE_LIST)
        
        AylaLogManager.shared().loggingLevel = .debug
        
        AylaNetworks.enableNetworkProfiler()
        
        UITabBar.appearance().tintColor = UIColor.auraTintColor()
        UINavigationBar.appearance().tintColor = UIColor.auraTintColor()
        
        setupGoogleSignIn()
        
        return true
    }
    
    /// Initialize Google sign-in
    func setupGoogleSignIn() {
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            let dict = NSDictionary(contentsOfFile: path)
            GIDSignIn.sharedInstance().serverClientID = dict!["SERVER_CLIENT_ID"] as! String
        }
    }
    
    // Instantiate and display a UIAlertViewController as needed
    func presentAlertController(_ title: String?, message: String?, withOkayButton: Bool, withCancelButton: Bool, okayHandler: (() -> Void)?, cancelHandler: (() -> Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        if withOkayButton {
            let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.default, handler:{(action) -> Void in
                if let okayHandler = okayHandler{
                    okayHandler()
                }
            })
            alert.addAction(okAction)
            if withCancelButton {
                let cancelAction = UIAlertAction (title: "Cancel", style: UIAlertActionStyle.cancel, handler:{(action) -> Void in
                    if let cancelHandler = cancelHandler{
                        cancelHandler()
                    }
                })
                alert.addAction(cancelAction)
            }
            displayViewController(alert)
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        
        // Aura Config
        if url.isFileURL && url.pathExtension == "auraconfig" {
            let fileManager = FileManager.default
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let filePath = paths[0].appendingPathComponent(url.lastPathComponent)
            do {
                try fileManager.moveItem(at: url, to: filePath)
            } catch _ {
                UIAlertController.alert("Error", message: "Failed to import file, it won't be available later from configurations list", buttonTitle: "OK", fromController: (self.window?.rootViewController)!)
            }
            
            openConfigAtURL(filePath)
            
            return true
        }
        
        // Google Sign In
        if GIDSignIn.sharedInstance().handle(url,
                                             sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                             annotation: options[UIApplicationOpenURLOptionsKey.annotation]) {
            return true
        }
        
        // Parse URL app was launched with
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryitems = components?.queryItems
        
        // If URL is sent from WI-Fi Setup Screen
        if url.host == "wifi_setup" {
            
            // Pull DSN from URL
            let dsnParam = queryitems?.filter({$0.name == "dsn"}).first
            let dsn = dsnParam?.value
            AylaLogD(tag: logTag, flag: 0, message:"Will Setup Wi-Fi for DSN: \(dsn)")
            
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
            AylaLogD(tag: logTag, flag: 0, message:"Will Confirm Sign Up with Token: \(token)")
            
            presentAlertController("Account Confirmation",
                                   message: "Would you like to confirm to this account?",
                                   withOkayButton: true,
                                   withCancelButton: true,
                                   okayHandler:{(action) -> Void in
                                    
                                    // Get LoginManager and send account confirmation token
                                    let loginManager = AylaNetworks.shared().loginManager
                                    loginManager.confirmAccount(withToken: (token)!, success: { () -> Void in
                                        self.presentAlertController("Account Confirmed",
                                            message: "Enter your credentials to log in",
                                            withOkayButton: true,
                                            withCancelButton: false,
                                            okayHandler:nil,
                                            cancelHandler:nil)
                                        }, failure: { (error) -> Void in
                                            self.presentAlertController("Account Confirmation Failed.",
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
                                        message: String.localizedStringWithFormat("Cannot currently parse url with %@ parameter", url.host ?? ""),
                                        withOkayButton: true,
                                        withCancelButton: false,
                                        okayHandler:nil,
                                        cancelHandler:nil)
        }
        
        return true
    }
    
    func openConfigAtURL(_ filePath :URL) {
        if let loadedConfig = loadConfigAtURL(filePath) {
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let developOptionsVC = storyboard.instantiateViewController(withIdentifier: "DeveloperOptionsViewController") as! DeveloperOptionsViewController
            let naviVC = UINavigationController(rootViewController: developOptionsVC)
            developOptionsVC.currentConfig = loadedConfig
            developOptionsVC.newConfigImport = true
            displayViewController(naviVC)
        }

    }
    
    func loadConfigAtURL(_ filePath :URL) -> AuraConfig? {
        let configData = try? Data(contentsOf: filePath)
        do {
            let configJSON = try JSONSerialization.jsonObject(with: configData!, options: .allowFragments)
            guard let configDict: NSDictionary = configJSON as? NSDictionary else {
                presentAlertController("Invalid config file", message: nil, withOkayButton: true, withCancelButton: false, okayHandler: nil, cancelHandler: nil)
                return nil
            }
            AylaLogD(tag: logTag, flag: 0, message:"Aura Config: \(configDict)")
            
            let configName = configDict["name"] as! String
            return AuraConfig(name: configName, config: configDict)
        }
        catch let error as NSError {
            AylaLogE(tag: logTag, flag: 0, message:"Error: \(error)")
            let message = String(format: "Something went wrong with the config file: \n%@", error.description)
            presentAlertController("Error", message: message, withOkayButton: true, withCancelButton: false, okayHandler: nil, cancelHandler: nil)
            return nil
        }
    }
    
    func displayViewController(_ controller: UIViewController){
        //  VC hierarchy is different if we are logged in than if we are not.
        //  This will ensure the VC is displayed.
        let topController = topViewController()
        topController.present(controller, animated: true, completion: nil)
    }
    
    func topViewController() -> UIViewController {
        let rootController = UIApplication.shared.keyWindow?.rootViewController
        return topViewControllerFromRoot(rootController!)
    }
    
    func topViewControllerFromRoot(_ rootVC:UIViewController) ->UIViewController{
        if rootVC.isKind(of: UITabBarController.self) {
            let tabVC = rootVC as! UITabBarController
            return topViewControllerFromRoot(tabVC.selectedViewController!)
        } else if rootVC.isKind(of: UINavigationController.self) {
            let navC = rootVC as! UINavigationController
            return topViewControllerFromRoot(navC.visibleViewController!)
        } else if let presentedVC = rootVC.presentedViewController {
            return topViewControllerFromRoot(presentedVC)
        } else {
            return rootVC
        }
    }
    
    // Called when AylaSessionManagerListener receives session closed event due to any error
    func displayLoginView() {
        
        // If topVC is already login VC, do nothing
        let topVC = topViewController()
        if topVC.isKind(of: LoginViewController.self)  {
            return;
        }
        
        // Pop all existing VCs to root. Root is Login VC
        let rootVC = UIApplication.shared.keyWindow?.rootViewController
        rootVC?.dismiss(animated: true, completion: nil)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        AylaNetworks.shared().pause()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AylaNetworks.shared().resume()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    }


}

