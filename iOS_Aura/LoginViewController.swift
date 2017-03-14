//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import PDKeychainBindingsController
import SAMKeychain
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class LoginViewController: UIViewController {
    private let logTag = "LoginViewController"
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var configLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    
    /// Id of a segue which is linked to `Main` storyboard.
    let segueIdToMain :String = "toMain"
    
    /// Current presenting alert controller.
    var alert: UIAlertController?
    
    var easterEgg: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoImageView.image = logoImageView.image?.withRenderingMode(.alwaysTemplate)
        logoImageView.tintColor = UIColor.aylaBahamaBlueColor()
        configLabel.text = ""
        settingsButton.tintColor = UIColor.aylaHippieGreenColor()
        // Add tap recognizer to dismiss keyboard.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let config = AuraConfig.currentConfig()
        if config.name != AuraConfig.ConfigNameUSDev {
            configLabel.text = "Config: " + config.name
        } else {
            configLabel.text = ""
        }
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        appVersionLabel.text = "v." + appVersion
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.autoLogin()
    }
  
    /**
     Login
     */
    func autoLogin() {
        let settings = AylaNetworks.shared().systemSettings
        if let username = PDKeychainBindings.shared().string(forKey: AuraUsernameKeychainKey) {
            let password = SAMKeychain.password(forService: settings.appId, account: username)
            self.usernameTextField.text = username
            self.passwordTextField.text = password
            
            if username.characters.count > 0 && password?.characters.count > 0 {
                login(self)
            }
        }
    }
    
    @IBAction func login(_ sender: AnyObject) {
        
        if (usernameTextField.text ?? "") == "" {
            UIAlertController.alert(nil, message: "Must supply a username", buttonTitle: "OK", fromController: self)
        }
        else if (passwordTextField.text ?? "") == "" {
            UIAlertController.alert(nil, message: "Must supply a password", buttonTitle: "OK", fromController: self)
        }
        else {
            
            self.dismissKeyboard()
            
            let settings = AylaNetworks.shared().systemSettings
            let username = usernameTextField.text!
            let password = passwordTextField.text!
            // Create auth provider with user input.
            let auth = AylaUsernameAuthProvider(username: username, password: password)
            
            let success = { (authorization: AylaAuthorization, sessionManager: AylaSessionManager) -> Void in
                PDKeychainBindings.shared().setString(username, forKey: AuraUsernameKeychainKey)
                SAMKeychain.setPassword(password, forService: settings.appId, account: username)
                
                // Register for AylaSessionListener
                (UIApplication.shared.delegate as! AppDelegate).auraSessionListener = AuraSessionListener.sharedListener
                (UIApplication.shared.delegate as! AppDelegate).auraSessionListener?.initializeAuraSessionListener()
                
                // Reset the Contact Manager for the new user
                ContactManager.sharedInstance.reload()
                
                self.dismissLoading(false, completion: { () -> Void in
                    do {
                        try SAMKeychain.setObject(authorization, forService: "LANLoginAuthorization", account: username)
                        
                    } catch {
                        let err = error as NSError
                        AylaLogE(tag: self.logTag, flag: 0, message:"Failed to save authorization: \(err.aylaServiceDescription)")
                    }
                    // Once succeeded, present view controller in `Main` storyboard.
                    self.performSegue(withIdentifier: self.segueIdToMain, sender: sessionManager)
                })

            }
            
            // Login with login manager
            self.presentLoading("Login...")
            let loginManager = AylaNetworks.shared().loginManager
            loginManager.login(with: auth, sessionName: AuraSessionOneName, success: success, failure: { [unowned loginManager] (error) -> Void in
                    if settings.allowOfflineUse {
                        do {
                        if let cachedAuth = try SAMKeychain.objectForService("LANLoginAuthorization", account: username) as? AylaAuthorization {
                            let provider = AylaCachedAuthProvider(authorization: cachedAuth)
                            loginManager.login(with: provider, sessionName: AuraSessionOneName, success: success, failure: { (error) in
                                self.dismissLoading(false, completion: { () -> Void in
                                    self.presentError(error)
                                })
                            })
                            return;
                        }
                        } catch _ {
                            AylaLogE(tag: self.logTag, flag: 0, message:"Failed to get cached authorization")
                        }
                    }
                    self.dismissLoading(false, completion: { () -> Void in
                        self.presentError(error as NSError)
                    })
            })
        }
    }
    
    @IBAction func resendConfirmation(_ sender: AnyObject) {
        
        if (usernameTextField.text ?? "") == "" {
            UIAlertController.alert(nil, message: "Please enter a username.", buttonTitle: "OK", fromController: self)
        }
        else {
            
            self.dismissKeyboard()
            
            // Login with login manager
            self.presentLoading("Resending confirmation...")
            let loginManager = AylaNetworks.shared().loginManager
            let template = AylaEmailTemplate(id: "aura_confirmation_template_01", subject: "Confirm your email", bodyHTML: nil)
            loginManager.resendConfirmationEmail(usernameTextField.text!, emailTemplate: template, success: {
                self.dismissLoading(false, completion: { () -> Void in
                    UIAlertController.alert("Confirmation resent", message: "Please check your inbox", buttonTitle: "OK", fromController: self)
                })
                }, failure: { (error) in
                    self.dismissLoading(false, completion: { () -> Void in
                        self.presentError(error)
                    })
            })
        }
    }
    
    @IBAction func resetPassword(_ sender: AnyObject) {
        if (usernameTextField.text ?? "") == "" {
            UIAlertController.alert(nil, message: "Please enter a username.", buttonTitle: "OK", fromController: self)
        }
        else if usernameTextField.text == AuraOptions.EasterEgg {
            self.easterEgg = true
            self.dismissKeyboard()
            self.performSegue(withIdentifier: "CustomConfigSegue", sender: nil)
        }
        else {
            
            self.dismissKeyboard()
            
            // Login with login manager
            self.presentLoading("Resetting password...")
            let loginManager = AylaNetworks.shared().loginManager
            let template = AylaEmailTemplate(id: "aura_passwd_reset_template_01", subject: "Password Reset Request", bodyHTML: nil)
            loginManager.requestPasswordReset(usernameTextField.text!, emailTemplate: template, success: {
                self.dismissLoading(false, completion: { () -> Void in
                    UIAlertController.alert("Password reset requested", message: "Please check your email for instructions on how to reset your password.", buttonTitle: "OK", fromController: self)
                })
                }, failure: { (error) in
                    self.dismissLoading(false, completion: { () -> Void in
                        self.presentError(error)
                    })
            })
        }
    }
    
    @IBAction func settingsButtonPressed(_ sender: AnyObject) {
        performSegue(withIdentifier: "CustomConfigSegue", sender: self)
    }
    /**
     Helpful method to present `loading`
     
     - parameter text: The text which shows on alert view
     */
    func presentLoading(_ text: String) {
        
        if let cur = alert {
            cur.dismiss(animated: true, completion: nil)
        }
        
        let newAlert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        self.present(newAlert, animated: true, completion: nil)
        self.alert = newAlert
    }
    
    /**
     Helpful method to dimiss current `loading` view
     
     - parameter animated:   True if this should be animated
     - parameter completion: A block which will be called after dismissing is completed.
     */
    func dismissLoading(_ animated:Bool, completion: (() -> Void)?) {
        self.dismiss(animated: animated, completion: completion)
    }
    
    /**
     Use to display an message.
     */
    func presentError(_ swiftError: Error) {
        let error = swiftError as NSError
        let alert = UIAlertController(title: "Error", message: "\(error.aylaServiceDescription) \n Status: \(error.httpResponseStatus ?? (String(error.code)))", preferredStyle: .alert)
        AylaLogD(tag: logTag, flag: 0, message:"Error :\(error)")
        
        alert.addAction(UIAlertAction(
            title: "Got it", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     Call to dismiss keyboard.
     */
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case "OAuthLoginSegueFacebook", "OAuthLoginSegueGoogle":
                let navigationViewController = segue.destination as! UINavigationController
                let oAuthController = navigationViewController.viewControllers.first! as! OAuthLoginViewController
                oAuthController.authType = (segueIdentifier == "OAuthLoginSegueFacebook") ? AylaOAuthType.facebook : AylaOAuthType.google
                // pass a reference to self to continue login after a sucessful OAuthentication
                oAuthController.mainLoginViewController = self
            case "CustomConfigSegue":
                let navigationViewController = segue.destination as! UINavigationController
                let configViewController = navigationViewController.viewControllers.first! as! DeveloperOptionsViewController
                configViewController.easterEgg = self.easterEgg ? true : false
                configViewController.fromLoginScreen = true
            default: break
            }
        }
    }
}
