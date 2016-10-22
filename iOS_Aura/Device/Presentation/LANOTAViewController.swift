//
//  LANOTAViewController.swift
//  iOS_Aura
//
//  Created by Andy on 6/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class LANOTAViewController: UIViewController {
    
    var device: AylaLANOTADevice?
    private var imageInfo: AylaOTAImageInfo?
    
    @IBOutlet private weak var consoleView: AuraConsoleTextView!
    @IBOutlet private weak var dsnField: UITextField!
    @IBOutlet private weak var lanIPField: UITextField!
    
    var progressAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.device != nil {
            dsnField.text = device!.dsn
            lanIPField.text = device!.lanIP
        }
        else {
            let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
            self.device = AylaLANOTADevice(sessionManager: sessionManager!, DSN: self.dsnField.text!, lanIP: self.lanIPField.text!)
        }
        self.device?.delegate = self
        // Add tap recognizer to dismiss keyboard.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction private func checkOTAInfoFromCloudAction(sender: UIButton) {
        if let dsn = dsnField.text, lanIP = lanIPField.text {
            if dsn.isEmpty || lanIP.isEmpty {
                self.showAlert("Error", message: "Please input the device's DSN and LAN IP Address.")
                return
            }
            let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
            self.device = AylaLANOTADevice(sessionManager: sessionManager!, DSN: dsn, lanIP: lanIP)
        }
        
        addDescription("Checking Service for an available OTA Image for this device.")
        self.device?.fetchOTAImageInfoWithSuccess({ [weak self] imageInfo in
            self?.imageInfo = imageInfo
            self?.addDescription("OTA image information: \(imageInfo)")
            
            sender.backgroundColor = UIColor.auraLeafGreenColor()
        },
        failure: { error in
            self.showAlert("Failed to fetch OTA image info", message: (error.localizedDescription))
            self.addDescription("Failed to fetch OTA image info: \(error.aylaServiceDescription)")
            
            sender.backgroundColor = UIColor.auraRedColor()
        })
    }

    @IBAction private func downloadOTAImageAction(sender: UIButton) {
        if let _ = imageInfo {
            addDescription("Attempting to download image from service.")
            
            let task = self.device?.fetchOTAImageFile(self.imageInfo!,
                progress: { progress in
                    self.addDescription("Download in Progress- \(progress.completedUnitCount)/\(progress.totalUnitCount)")
                },
                success: {
                    self.progressAlert?.dismissViewControllerAnimated(false, completion: nil)
                    self.showAlert("Success", message: "The image has been downloaded and can now be pushed to the device.")
                    self.addDescription("OTA Image Download Complete.")
                    sender.backgroundColor = UIColor.auraLeafGreenColor()
                },
                failure: { error in
                    self.progressAlert?.dismissViewControllerAnimated(false, completion: nil)
                    let message = "Failed to download image: \(error.aylaServiceDescription)"
                    self.showAlert("Error", message: message)
                    self.addDescription(message)
                    sender.backgroundColor = UIColor.auraRedColor()
            })
            
            showProgressAlert {
                task?.cancel()
            }
        }
        else {
            self.showAlert("Error", message: "Please fetch OTA information first")
        }
    }
    
    @IBAction private func pushImageToDeviceAction(sender: UIButton) {
        if self.device!.isOTAImageAvailable() {
            addDescription("Attempting to push OTA image to the device.")
            
            let task = self.device?.pushOTAImageToDeviceWithSuccess({
                    self.addDescription("Success!\nDevice will now attempt to apply the OTA image.")
                    sender.backgroundColor = UIColor.auraLeafGreenColor()
                },
                 failure: { error in
                    self.progressAlert?.dismissViewControllerAnimated(false, completion: nil)
                    self.showAlert("Error", message: error.localizedDescription)
                    self.addDescription("Error: \(error.description)")
                    sender.backgroundColor = UIColor.auraRedColor()
            })
            
            showProgressAlert {
                task?.cancel()
            }
        }
        else {
            addDescription("No OTA image file found, please download it first.")
        }
    }
    
    private func showAlert(title:String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func showProgressAlert(cancelBlock : (Void) -> Void) {
        let alert = UIAlertController(title: nil, message: "LAN OTA in progress...", preferredStyle: .Alert)
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        spinner.center = CGPointMake(130.5, 55.5)
        spinner.color = UIColor.blackColor()
        spinner.startAnimating()
        alert.view.addSubview(spinner)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            cancelBlock()
        }
        alert.addAction(cancelAction);
        self.presentViewController(alert, animated: true, completion: nil)
        
        self.progressAlert = alert
    }
    
    /**
     Use this method to add a description to description text view.
     */
    private func addDescription(description: String) {
        consoleView.addLogLine(description)
    }
}

// MARK: - AylaLANOTADeviceDelegate
extension LANOTAViewController: AylaLANOTADeviceDelegate {
    func lanOTADevice(device: AylaLANOTADevice, didUpdateImagePushStatus status: ImagePushStatus) {
        var display = ""
        if status == ImagePushStatus.Done {
            display = "Done"
            self.progressAlert?.dismissViewControllerAnimated(false, completion: nil)
        }
        else if status == ImagePushStatus.Initial {
            display = "Initializing"
        }
        else {
            display = "Error"
            self.progressAlert?.dismissViewControllerAnimated(false, completion: nil)
        }
        
        self.addDescription("OTA Image Push to Device - Status:\(display)")
    }
}
