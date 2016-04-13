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
    
    func configure(device:AylaDevice) {
        
        nameLabel.text = device.productName
        dsnLabel.text = device.dsn
        connectivityLabel.text = device.connectionStatus
        if device.connectionStatus == "Online" {
            connectivityLabel.textColor = UIColor.greenColor()
        } else {
            connectivityLabel.textColor = UIColor.redColor()
        }
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGrayColor().CGColor
    }
}
