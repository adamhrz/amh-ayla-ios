//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    /// Id of a segue which is linked to `Main` storyboard.
    let segueIdToMain :String = "toMain"
    
    /// Current presenting alert controller.
    var alert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add tap recognizer to dismiss keyboard.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
  
    /**
     Login
     */
    @IBAction func login(sender: AnyObject) {
        
        if (usernameTextField.text ?? "") == "" {
            usernameTextField.text = "CAN NOT BE BLANK"
        }
        else if (passwordTextField.text ?? "") == "" {
            passwordTextField.text = "CAN NOT BE BLANK"
        }
        else {
            
            self.dismissKeyboard()
            
            // Create auth provider with user input.
            let auth = AylaUsernameAuthProvider(username: usernameTextField.text!, password: passwordTextField.text!)
            
            // Login with login manager
            self.presentLoading("Login...")
            let loginManager = AylaCoreManager.sharedManager().loginManager
            loginManager.loginWithAuthProvider(auth, sessionName: AuraSessionOneName, success: { (_, sessionManager) -> Void in
                
                self.dismissLoading(false, completion: { () -> Void in
                    // Once succeeded, present view controller in `Main` storyboard.
                    self.performSegueWithIdentifier(self.segueIdToMain, sender: sessionManager)
                })
                
                }, failure: { (error) -> Void in

                    self.dismissLoading(false, completion: { () -> Void in
                        self.presentError(error)
                    })
            })
        }
    }
    
    /**
     Helpful method to present `loading`
     
     - parameter text: The text which shows on alert view
     */
    func presentLoading(text: String) {
        
        if let cur = alert {
            cur.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let newAlert = UIAlertController(title: text, message: nil, preferredStyle: .Alert)
        self.presentViewController(newAlert, animated: true, completion: nil)
        self.alert = newAlert
    }
    
    /**
     Helpful method to dimiss current `loading` view
     
     - parameter animated:   True if this should be animated
     - parameter completion: A block which will be called after dismissing is completed.
     */
    func dismissLoading(animated:Bool, completion: (() -> Void)?) {
        self.dismissViewControllerAnimated(animated, completion: completion)
    }
    
    /**
     Use to display an message.
     */
    func presentError(error: NSError) {
        let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(
            title: "Got it", style: .Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
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
}
