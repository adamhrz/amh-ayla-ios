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
    @IBOutlet weak var dssActiveLabel: UILabel!
    @IBOutlet weak var lanModeActiveLabel: UILabel!
    
    
    func configure(device:AylaDevice) {
        nameLabel.text = String(format: "%@", device.productName!)
        dsnLabel.text = String(format: "%@ %@", "DSN: ", device.dsn!)
        
        let connStatus = String.stringFromStringNumberOrNil(device.connectionStatus)
        connectivityLabel.text = connStatus
        connectivityLabel.textColor = connStatus == "Online" ? UIColor.auraLeafGreenColor() : UIColor.auraRedColor()
        
        oemModelLabel.text = String(format: "%@ %@", "OEM Model: ", String.stringFromStringNumberOrNil(device.oemModel))
        modelLabel.text = String(format: "%@ %@", "Model: ", String.stringFromStringNumberOrNil(device.model))
        macAddressLabel.text = String(format: "%@ %@", "MAC: ", String.stringFromStringNumberOrNil(device.mac))
        lanIPAddressLabel.text = String(format: "%@ %@", "LAN IP: ", String.stringFromStringNumberOrNil(device.lanIp))
        
        self.lanModeActiveLabel.textColor = UIColor.darkGrayColor()
        self.lanModeActiveLabel.highlightedTextColor = UIColor.auraLeafGreenColor()
        self.lanModeActiveLabel.highlighted = device.isLanModeActive() ? true : false
        
        let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName)
        self.dssActiveLabel.textColor = UIColor.darkGrayColor()
        self.dssActiveLabel.highlightedTextColor = UIColor.auraLeafGreenColor()
        self.dssActiveLabel.highlighted = sessionManager!.isDSActive() ? true : false
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGrayColor().CGColor

    }
}
