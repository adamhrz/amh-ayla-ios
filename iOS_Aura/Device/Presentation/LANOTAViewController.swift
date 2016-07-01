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
    var imageInfo: AylaOTAImageInfo?
    
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var dsnField: UITextField!
    @IBOutlet weak var lanIPField: UITextField!
    
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
    }
    
    @IBAction func checkOTAInfoFromCloudAction(sender: UIButton) {
        updatePrompt("checkOTAInfoFromCloud")
        if let dsn = dsnField.text, lanIP = lanIPField.text {
            if dsn.isEmpty || lanIP.isEmpty {
                self.showAlert("Error", message: "Please input device DSN and lan IP")
                return
            }
            let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
            self.device = AylaLANOTADevice(sessionManager: sessionManager!, DSN: dsn, lanIP: lanIP)
        }
        
        self.device?.fetchOTAImageInfoWithSuccess({ [weak self] imageInfo in
            self?.imageInfo = imageInfo
            self?.addDescription("OTA image infor:\(imageInfo)")
        },
        failure: { error in
            self.showAlert("Failed to fetch OTA image info", message: error.localizedDescription)
            self.addDescription("Failed to fetch OTA image info:\(error)")
        })
    }

    @IBAction func downloadOTAImageAction(sender: UIButton) {
        updatePrompt("downloadOTAImage")
        if let _ = imageInfo {
            self.device?.fetchOTAImageFile(self.imageInfo!,
            success: {
                self.showAlert("Success", message: "You can push the OTA image to device now")
            },
            failure: { error in
                self.showAlert("Download image failed", message: error.localizedDescription)
            })
        }
        else {
            self.showAlert("Image info is empty", message: "Please fetch OTA info first")
        }
    }
    
    @IBAction func pushImageToDeviceAction(sender: UIButton) {
        updatePrompt("pushImageToDevice")
        addDescription("Start push image to device.")
        self.device?.pushOTAImageToDeviceWithSuccess({ 
            self.addDescription("Success: Device will download the OTA image soon!")
        },
        failure: { error in
            self.showAlert("Error", message: error.localizedDescription)
            self.addDescription("Error: \(error.description)")
        })
    }
    
    func showAlert(title:String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func updatePrompt(prompt: String?) {
        self.navigationController?.navigationBar.topItem?.prompt = prompt
    }
    
    /**
     Use this method to add a description to description text view.
     */
    func addDescription(description: String) {
        descriptionView.text = "\(descriptionView.text) \n\(description)"
    }
}

extension LANOTAViewController: AylaLANOTADeviceDelegate {
    func lanOTADevice(device: AylaLANOTADevice, didUpdateImagePushStatus status: ImagePushStatus) {
        self.addDescription("Push image to device status update:\(status.rawValue)")
    }
}
