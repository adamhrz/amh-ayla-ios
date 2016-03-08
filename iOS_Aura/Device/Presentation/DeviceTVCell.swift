//
//  DeviceTVC.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceTVCell : UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dsnLabel: UILabel!
    @IBOutlet weak var connectivityLabel: UILabel!
    @IBOutlet weak var oemModelLabel: UILabel!
    @IBOutlet weak var label1: UILabel!
    
    var dsn: String
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    required init?(coder aDecoder: NSCoder) {
        dsn = ""
        super.init(coder: aDecoder)
    }
    
    func configure(device: AylaDevice) {
        assert(device.dsn != nil, "DSN can not be found")
        dsn = device.dsn!
        nameLabel.text = device.productName
        dsnLabel.text = device.dsn
        oemModelLabel.text = device.oemModel
        connectivityLabel.text = device.connectionStatus
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
