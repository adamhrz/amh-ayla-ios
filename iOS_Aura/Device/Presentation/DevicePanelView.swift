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
    @IBOutlet weak var ipAddressLabel: UILabel!
    
    
    func configure(device:AylaDevice) {
        nameLabel.text = String(format: "%@", device.productName!)
        dsnLabel.text = String(format: "%@ %@", "DSN: ", device.dsn!)
        connectivityLabel.text = device.connectionStatus
        oemModelLabel.text = String(format: "%@ %@", "OEM Model: ", device.oemModel!)
        modelLabel.text = String(format: "%@ %@", "Model: ", device.model!)
        
        var macAddress = String()
        if let mac = device.mac {
            macAddress = mac
        }
        else {
            macAddress = "(null)"
        }
        macAddressLabel.text = String(format: "%@ %@", "MAC: ", macAddress)
        
        var ipAddress = String()
        if let mac = device.lanIp {
            ipAddress = mac
        }
        else {
            ipAddress = "(null)"
        }
        ipAddressLabel.text = String(format: "%@ %@", "LAN IP: ", ipAddress)
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGrayColor().CGColor

    }
}
