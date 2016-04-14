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
    
    
    func configure(device:AylaDevice) {
        nameLabel.text = String(format: "%@", device.productName!)
        dsnLabel.text = String(format: "%@ %@", "DSN: ", device.dsn!)
        
        let connStatus = String.stringOrNull(device.connectionStatus)
        connectivityLabel.text = connStatus
        connectivityLabel.textColor = connStatus == "Online" ? UIColor.auraLeafGreenColor() : UIColor.auraRedColor()
        
        oemModelLabel.text = String(format: "%@ %@", "OEM Model: ", String.stringOrNull(device.oemModel))
        modelLabel.text = String(format: "%@ %@", "Model: ", String.stringOrNull(device.model))
        macAddressLabel.text = String(format: "%@ %@", "MAC: ", String.stringOrNull(device.mac))
        lanIPAddressLabel.text = String(format: "%@ %@", "LAN IP: ", String.stringOrNull(device.lanIp))
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGrayColor().CGColor

    }
}
