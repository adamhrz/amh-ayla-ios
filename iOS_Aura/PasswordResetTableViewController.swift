//
//  PasswordResetTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class PasswordResetTableViewController: UITableViewController {

    var passwordResetToken : String!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordConfirmationTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    @IBAction func cancel(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func resetPassword(sender: AnyObject) {
        let password = passwordTextField.text!
        let passwordConfirmation = passwordConfirmationTextField.text!
        if password.characters.count == 0 || passwordConfirmation.characters.count == 0 {
            UIAlertController.alert("Error", message: "Enter a password and confirmation", buttonTitle: "OK", fromController: self)
            return
        } else if password != passwordConfirmation {
            UIAlertController.alert("Error", message: "Password and confirmation don't match", buttonTitle: "OK", fromController: self)
            return
        }
        let loginManager = AylaCoreManager.sharedManager().loginManager
        loginManager.resetPasswordTo(passwordTextField.text!, token: passwordResetToken, success: {
            let presentingController = self.presentingViewController
            self.dismissViewControllerAnimated(true, completion: {
                UIAlertController.alert("Done", message: "Password has been changed, please login", buttonTitle: "OK", fromController: presentingController!)
                return
            })
            
            return
            }) { (error) in
                UIAlertController.alert("Error", message: "Bad password reset token", buttonTitle: "OK", fromController: self)
                return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
