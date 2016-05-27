//
//  DeviceShareTVCell.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/6/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceShareTVCell : UITableViewCell {
    
    static var expandedRowHeight: CGFloat = 215.0
    static var collapsedRowHeight: CGFloat = 65.0
    
    @IBOutlet weak var dsnLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var oemModelLabel: UILabel!
    
    @IBOutlet weak var detailView: UIView!
    
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var operationLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var expiryDateLabel: UILabel!
    
    var dsn: String
    var deviceName: String
    var oemModel: String
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    required init?(coder aDecoder: NSCoder) {
        dsn = ""
        deviceName = ""
        oemModel = ""

        super.init(coder: aDecoder)
    }
    
    func configure(share: AylaShare, device: AylaDevice?, expanded:Bool) {
        
        deviceName = device?.productName ?? "unknown"
        deviceNameLabel.text = String(format:"%@", deviceName)
        oemModel = device?.oemModel ?? "unknown"
        oemModelLabel.text = String(format:"%@", oemModel)
        
        dsn = share.resourceId
        dsnLabel.text = dsn
        
        let targetUser = share.userEmail ?? "none"
        userEmailLabel.text = String(format:"%@", targetUser)
        
        let roleName = share.roleName ?? "none"
        roleLabel.text = String(format:"%@", roleName)
        
        var operationLabelText : String
        let operation = share.operation
        switch operation as AylaShareOperation {
        case .None:
            operationLabelText = "None"
        case .ReadOnly:
            operationLabelText = "Read Only"
        case .ReadAndWrite:
            operationLabelText = "Read/Write"
        }
            
        operationLabel.text = String(format:"%@", operationLabelText)
        
        setDateLabelValue(share.startAt, label: startDateLabel)
        setDateLabelValue(share.endAt, label: expiryDateLabel)

        self.detailView.hidden = !expanded
    }
    
    func setDateLabelValue(date: NSDate?, label: UILabel) {
        if let date = date {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .MediumStyle
            dateFormatter.timeStyle = .ShortStyle
            label.text = dateFormatter.stringFromDate(date)
        }
        else {
            label.text = "none"
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
