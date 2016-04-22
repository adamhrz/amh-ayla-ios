//
//  DevicePanelView.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DevicePanelView: UIView {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dsnLabel: UILabel!
    @IBOutlet weak var connectivityLabel: UILabel!
    @IBOutlet weak var oemModelLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var macAddressLabel: UILabel!
    @IBOutlet weak var lanIPAddressLabel: UILabel!
    @IBOutlet weak var lanModeActiveLabel: UILabel!
    
    
    func configure(device:AylaDevice) {
        nameLabel.text = String(format: "%@", device.productName!)
        dsnLabel.text = String(format: "%@ %@", "DSN: ", device.dsn!)
        
        let connStatus = String.stringFromStringNumberOrNil(device.connectionStatus)
        connectivityLabel.text = String(format: "%@", String.stringFromStringNumberOrNil(connStatus))
        connectivityLabel.textColor = connStatus == "Online" ? UIColor.auraLeafGreenColor() : UIColor.auraRedColor()
        
        oemModelLabel.text = String(format: "%@ %@", "OEM Model: ", String.stringFromStringNumberOrNil(device.oemModel))
        modelLabel.text = String(format: "%@ %@", "Model: ", String.stringFromStringNumberOrNil(device.model))
        macAddressLabel.text = String(format: "%@ %@", "MAC: ", String.stringFromStringNumberOrNil(device.mac))
        lanIPAddressLabel.text = String(format: "%@ %@", "LAN IP: ", String.stringFromStringNumberOrNil(device.lanIp))
        
        self.lanModeActiveLabel.textColor = UIColor.lightGrayColor()
        self.lanModeActiveLabel.highlightedTextColor = UIColor.auraLeafGreenColor()
        if device.isLanModeActive() {
            self.lanModeActiveLabel.highlighted = true
            self.lanModeActiveLabel.text = "Active"
        }
        else {
            self.lanModeActiveLabel.highlighted = false
            self.lanModeActiveLabel.text = "Inactive"
        }
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGrayColor().CGColor

    }
}
