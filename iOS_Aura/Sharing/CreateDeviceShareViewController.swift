//
//  CreateDeviceShareViewController.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/6/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK
import UIKit

class CreateDeviceShareViewController: UIViewController, UITextFieldDelegate{
    
    /// Device model used by view controller to present this device.
    var sessionManager : AylaSessionManager?
    var deviceViewModel : DeviceViewModel!
    
    var startDate : NSDate?
    var expiryDate : NSDate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var roleNameTextField: UITextField!
    @IBOutlet weak var capabilitySelector: UISegmentedControl!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var expiryDateTextField: UITextField!
    @IBOutlet weak var expiryDatePicker: UIDatePicker!
    @IBOutlet weak var createShareButton: AuraButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
            self.sessionManager = sessionManager
        }
        else {
            print("- WARNING - session manager can't be found")
        }

        let cancel = UIBarButtonItem(barButtonSystemItem:.Cancel, target: self, action: #selector(RegistrationViewController.cancel))
        self.navigationItem.leftBarButtonItem = cancel
        self.emailTextField.delegate = self
        self.roleNameTextField.delegate = self
        self.startDateTextField.delegate = self
        self.expiryDateTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(CreateDeviceShareViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        capabilitySelector.tintColor = UIColor.auraLeafGreenColor()
        self.expiryDateTextField.inputView = UIView()
        self.startDateTextField.inputView = UIView()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        titleLabel.text = String(format:"Share %@", deviceViewModel.device.productName!)
        super.viewWillAppear(animated)
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func cancel() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func toggleViewVisibilityAnimated(view: UIView){
        dispatch_async(dispatch_get_main_queue()) { 
            UIView.animateWithDuration(0.33) {
                view.hidden = !(view.hidden)
            }
        }
    }
    
    func setDateTextFieldValue(date: NSDate, field: UITextField) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        field.text = dateFormatter.stringFromDate(date)
    }
    
    @IBAction func startDateFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(self.startDatePicker)
    }
    
    @IBAction func expiryDateFieldTapped(sender:AnyObject){
        toggleViewVisibilityAnimated(self.expiryDatePicker)
    }

    @IBAction func startPickerChanged(sender: UIDatePicker) {
        startDate = sender.date
        setDateTextFieldValue(startDate!, field:startDateTextField)
    }
    
    @IBAction func expiryPickerChanged(sender: UIDatePicker) {
        expiryDate = sender.date
        setDateTextFieldValue(expiryDate!, field:expiryDateTextField)
    }
    
    @IBAction func createButtonPressed(sender: AnyObject) {
        self.createShareButton.enabled = false
        let email = emailTextField.text
        if email == nil || email!.characters.count < 1 {
            UIAlertController.alert("Error", message: "Please provide an email", buttonTitle: "OK",fromController: self)
            return;
        }
        let roleName = roleNameTextField.text == "" ? nil : roleNameTextField.text
        var operation : AylaShareOperation
        if roleName != nil {
            operation = AylaShareOperation.None
        }
        else {
            let operationIndex = capabilitySelector.selectedSegmentIndex
            switch operationIndex {
            case 0:
                operation = AylaShareOperation.ReadAndWrite
            case 1:
                operation = AylaShareOperation.ReadOnly
            case 2:
                operation = AylaShareOperation.None
            default:
                operation = AylaShareOperation.ReadAndWrite
            }
        }
        let newShare = AylaShare(email: email!,
                                 resourceName:"device",
                                 resourceId: deviceViewModel.device.dsn!,
                                 roleName: roleName,
                                 operation:  operation,
                                 startAt: startDate,
                                 endAt: expiryDate)
        deviceViewModel.shareDevice(self, withShare: newShare, successHandler: { (share) in
            self.cancel()
            self.createShareButton.enabled = true
            }) { (error) in
                UIAlertController.alert("Error", message:error.localizedDescription , buttonTitle: "OK",fromController: self)
                self.createShareButton.enabled = true
        }
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == self.startDateTextField {
            toggleViewVisibilityAnimated(startDatePicker)
            return false
        } else if textField == self.expiryDateTextField {
            toggleViewVisibilityAnimated(expiryDatePicker)
            return false
        } else {
            return true
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {

    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if textField == self.startDateTextField {
            startDatePicker.reloadInputViews()
            startDate = nil
            return true
        } else if textField == self.expiryDateTextField {
            expiryDatePicker.reloadInputViews()
            expiryDate = nil
            return true
        } else {
            return false
        }
    }

}
