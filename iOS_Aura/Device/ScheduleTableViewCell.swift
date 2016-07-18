//
//  ScheduleTableViewCell.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleTableViewCell : UITableViewCell {
    
    
    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var infoLabelTop: UILabel!
    @IBOutlet private weak var infoLabelBottom: UILabel!
    @IBOutlet private weak var actionActiveLabel: UILabel!
    

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
    
}
