//
//  ScheduleTableViewCell.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 7/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleTableViewCell : UITableViewCell {
    
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var infoLabelTop: UILabel!
    @IBOutlet weak var infoLabelBottom: UILabel!
    @IBOutlet weak var actionActiveLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    func configure(schedule: AylaSchedule) {
        self.mainLabel.text = "\(schedule.displayName ?? "") (\(schedule.name))"
        
        let startTimeEachDay = "\(schedule.startTimeEachDay ?? "")"
        let endTimeEachDay = "\(schedule.endTimeEachDay ?? "No end time")"
        
        let startDate = "\(schedule.startDate ?? "Immediately")"
        let endDate = "\(schedule.endDate ?? "indefinite")"
        let utc = "\(schedule.utc ? "UTC" : "Non-UTC (Local)")"
        
        
        self.infoLabelTop?.text = "Start \(startDate) - \(startTimeEachDay), \(utc)"
        
        self.infoLabelBottom?.text = "End \(endDate) - \(endTimeEachDay), \(utc)"

        if schedule.active {
            actionActiveLabel.text = "Active"
            actionActiveLabel.textColor = UIColor.auraLeafGreenColor()
        } else {
            actionActiveLabel.text = "Inactive"
            actionActiveLabel.textColor = UIColor.auraRedColor()
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
