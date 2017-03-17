//
//  DevicePanelView.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import Ayla_LocalDevice_SDK

class DevicePanelView: UIView {
    private let logTag = "DevicePanelView"
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dsnLabel: UILabel!
    @IBOutlet weak var connectivityLabel: UILabel!
    @IBOutlet weak var oemModelLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var macAddressLabel: UILabel!
    @IBOutlet weak var lanIPAddressLabel: UILabel!
    @IBOutlet weak var lanModeActiveLabel: UILabel!
    @IBOutlet weak var lanModeHeaderLabel: UILabel!
    @IBOutlet weak var timeZoneLabel: UILabel!
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var shareNamesLabel: UILabel!
    @IBOutlet weak var sharingNamesView: UIView!
    
    func configure(_ device:AylaDevice, sharesModel: DeviceSharesModel?) {
        nameLabel.text = String(format: "%@", device.productName!)
        dsnLabel.text = String(format: "%@ %@", "DSN: ", device.dsn!)
        
        let connStatus = String.stringFromStringNumberOrNil(device.connectionStatus as AnyObject?)
        connectivityLabel.text = String(format: "%@", String.stringFromStringNumberOrNil(connStatus as AnyObject?))
        connectivityLabel.textColor = connStatus == "Online" ? UIColor.auraLeafGreenColor() : UIColor.auraRedColor()
        
        oemModelLabel.text = String(format: "%@ %@", "OEM Model: ", String.stringFromStringNumberOrNil(device.oemModel as AnyObject?))
        modelLabel.text = String(format: "%@ %@", "Model: ", String.stringFromStringNumberOrNil(device.model as AnyObject?))
        lanIPAddressLabel.text = String(format: "%@ %@", "LAN IP: ", String.stringFromStringNumberOrNil(device.lanIp as AnyObject?))
        
        self.lanModeActiveLabel.textColor = UIColor.lightGray
        self.lanModeActiveLabel.highlightedTextColor = UIColor.auraLeafGreenColor()
        
        var macAddressLabelString:String
        var lanModeHeaderLabelString:String
        var activeLabelBool:Bool

        if let bleDevice = device as? AylaBLEDevice {
            let btID = String.stringFromStringNumberOrNil(bleDevice.bluetoothIdentifier?.uuidString as AnyObject?)
            macAddressLabelString = String(format: "%@ %@", "BT ID: ", String.stringFromStringNumberOrNil(btID as AnyObject?))
            lanModeHeaderLabelString = "Bluetooth:"
            activeLabelBool = bleDevice.isConnectedLocal
            
        } else {
            macAddressLabelString = String(format: "%@ %@", "MAC: ", String.stringFromStringNumberOrNil(device.mac as AnyObject?))
            lanModeHeaderLabelString = "LAN Mode:"
            activeLabelBool = device.isLanModeActive()
        }
        macAddressLabel.text = macAddressLabelString
        lanModeHeaderLabel.text = lanModeHeaderLabelString
        
        if activeLabelBool {
            self.lanModeActiveLabel.isHighlighted = true
            self.lanModeActiveLabel.text = "Active"
        }
        else {
            self.lanModeActiveLabel.isHighlighted = false
            self.lanModeActiveLabel.text = "Inactive"
        }
        
        let timeZoneBase = "Time Zone: "
        if (self.timeZoneLabel == nil) {
            self.timeZoneLabel.text = timeZoneBase
        }
        device.fetchTimeZone(success: { (timeZone) in
            self.timeZoneLabel.text = timeZoneBase + String.stringFromStringNumberOrNil(timeZone.tzID as AnyObject?)
        }) { (error) in
            self.timeZoneLabel.text = timeZoneBase + "Unknown"
        }

        var sharesText = "Not Shared"
        if sharesModel != nil {
            if device.grant == nil {
                if let ownedShares = sharesModel?.ownedSharesForDevice(device){
                    if ownedShares.count > 0 {

                        sharesText = String(format:"Shared to %d %@", ownedShares.count, ownedShares.count > 1 ? "people" : "person" )
                        var shareNamesText = ""
                        for share in ownedShares {
                            if shareNamesText != "" {
                                shareNamesText = shareNamesText + "\n" + share.userEmail }
                            else {
                                shareNamesText = share.userEmail
                            }
                        }
                        UIView.animate(withDuration: 0.2, animations: {
                            self.shareNamesLabel.text = shareNamesText
                            self.sharingNamesView.isHidden = false
                        })
                    } else {
                        UIView.animate(withDuration: 0.2, animations: {
                            self.sharingNamesView.isHidden = true
                        })
                    }
                }
            }
            else {
                if let receivedShare = sharesModel?.receivedShareForDevice(device) {
                    sharesText = "Shared to you by " + receivedShare.ownerProfile.email
                }

            }
            self.sharesLabel.text = sharesText
        } else {
            AylaLogD(tag: logTag, flag: 0, message:"Panel View Shares Model is NIL")
            self.sharesLabel.text = "Unknown"
        }
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGray.cgColor
    }
}
