//
//  ProfileTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/12/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class ProfileTableViewController: UITableViewController {
    var user: AylaUser!
    let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneCountryCodeTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var companyTextField: UITextField!
    @IBOutlet weak var streetTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var devKitNumTextField: UITextField!
    
    @IBAction func updatePasswordAction(sender: AnyObject) {
        if self.currentPasswordTextField.text?.characters.count == 0 || self.passwordTextField.text?.characters.count == 0 || self.confirmPasswordTextField.text?.characters.count == 0 {
            // show error
            UIAlertController.alert("Error", message: "All three password fields are required", buttonTitle: "OK", fromController: self)
            return
        } else if  self.passwordTextField.text != self.confirmPasswordTextField.text {
            // show error
            UIAlertController.alert("Error", message: "Password and confirmation don't match", buttonTitle: "OK", fromController: self)
            return
        }
        // call update password
        sessionManager?.updatePassword(self.currentPasswordTextField.text!, newPassword: self.passwordTextField.text!, success: {
            //display success message
            UIAlertController.alert("Done", message: "Password has been updated", buttonTitle: "OK", fromController: self)
            }, failure: { (error) in
                // display error from cloud
                // todo: check for the specific error
                UIAlertController.alert("Error", message: "Wrong password", buttonTitle: "OK", fromController: self)
        })
    }
    
    @IBAction func updateProfileAction(sender: AnyObject) {
        //Validate required fields
        if self.emailTextField.text!.characters.count == 0 {
            return
        } else if self.firstNameTextField.text!.characters.count == 0 {
            return
        } else if self.lastNameTextField.text!.characters.count == 0 {
            
            return
        }
        // put information from textFields into the user
        self.user.email = self.emailTextField.text!
        self.user.firstName = self.firstNameTextField.text!
        self.user.lastName = self.lastNameTextField.text!
        self.user.phoneCountryCode = self.phoneCountryCodeTextField.text
        self.user.phone = self.phoneTextField.text
        self.user.company = self.companyTextField.text
        self.user.street = self.streetTextField.text
        self.user.city = self.cityTextField.text
        self.user.state = self.stateTextField.text
        self.user.zip = self.zipTextField.text
        self.user.country = self.countryTextField.text
        self.user.devKitNum = NSNumberFormatter().numberFromString(self.devKitNumTextField.text!)
        
        // call update profile
        sessionManager?.updateUserProfile(user, success: { 
            // show success message
            UIAlertController.alert("Done", message: "Profile updated", buttonTitle: "OK", fromController: self)
            }, failure: { (error) in
                //show error message
                UIAlertController.alert("Error", message: "An error occurred", buttonTitle: "OK", fromController: self)
        })
    }
    
    func syncUI() {
        self.emailTextField.text = self.user.email
        self.firstNameTextField.text = self.user.firstName
        self.lastNameTextField.text = self.user.lastName
        self.phoneCountryCodeTextField.text = self.user.phoneCountryCode
        self.phoneTextField.text = self.user.phone
        self.companyTextField.text = self.user.company
        self.streetTextField.text = self.user.street
        self.cityTextField.text = self.user.city
        self.stateTextField.text = self.user.state
        self.zipTextField.text = self.user.zip
        self.countryTextField.text = self.user.country
        self.devKitNumTextField.text = self.user.devKitNum?.stringValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionManager?.fetchUserProfile({ (user) in
            self.user = user
            
            self.syncUI()
            }, failure: { (error) in
                print(error)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
