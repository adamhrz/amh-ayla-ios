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
        
        updatePrompt("checkOTAInfoFromCloud")
        addDescription("Checking Service for an available OTA Image for this device.")
        self.device?.fetchOTAImageInfoWithSuccess({ [weak self] imageInfo in
            self?.imageInfo = imageInfo
            self?.addDescription("OTA image information: \(imageInfo)")
        },
        failure: { error in
            self.showAlert("Failed to fetch OTA image info", message: (error.localizedDescription))
            self.addDescription("Failed to fetch OTA image info: \(error.aylaServiceDescription ?? String(error.userInfo))")
        })
    }

    @IBAction private func downloadOTAImageAction(sender: UIButton) {
        if let _ = imageInfo {
            updatePrompt("downloadOTAImage")
            addDescription("Attempting to download image from service.")
            self.device?.fetchOTAImageFile(self.imageInfo!,
                progress: { progress in
                    self.addDescription("Download in Progress- \(progress.completedUnitCount)/\(progress.totalUnitCount)")
                },
                success: {
                    self.showAlert("Success", message: "The image has been downloaded and can now be pushed to the device.")
                    self.addDescription("OTA Image Download Complete.")
                },
                failure: { error in
                    let message = "Failed to download image: \(error.aylaServiceDescription ?? String(error.userInfo))"
                    self.showAlert("Error", message: message)
                    self.addDescription(message)
            })
        }
        else {
            self.showAlert("Error", message: "Please fetch OTA information first")
        }
    }
    
    @IBAction private func pushImageToDeviceAction(sender: UIButton) {
        if self.device!.isOTAImageAvailable() {
            updatePrompt("pushImageToDevice")
            addDescription("Attempting to push OTA image to the device.")
            self.device?.pushOTAImageToDeviceWithSuccess({
                self.addDescription("Success!\nDevice will now attept to apply the OTA image.")
                },
                                                         failure: { error in
                                                            self.showAlert("Error", message: error.localizedDescription)
                                                            self.addDescription("Error: \(error.description)")
            })
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
    
    private func updatePrompt(prompt: String?) {
        self.navigationController?.navigationBar.topItem?.prompt = prompt
    }
    
    /**
     Use this method to add a description to description text view.
     */
    private func addDescription(description: String) {
        consoleView.addLogLine(description)
    }
}

extension LANOTAViewController: AylaLANOTADeviceDelegate {
    func lanOTADevice(device: AylaLANOTADevice, didUpdateImagePushStatus status: ImagePushStatus) {
        var display = ""
        if status == ImagePushStatus.Done {
            display = "Done"
        }
        else if status == ImagePushStatus.Initial {
            display = "Initializing"
        }
        else {
            display = "Error"
        }
        
        self.addDescription("OTA Image Push to Device - Status:\(display)")
    }
}
