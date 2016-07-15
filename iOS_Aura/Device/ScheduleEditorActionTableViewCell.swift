//
//  ScheduleEditorActionTableViewCell.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 7/12/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleEditorActionTableViewCell : UITableViewCell {
    
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var actionActiveLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    private func mainLabelTextFromScheduleAction (action: AylaScheduleAction) -> String {
        let text = "Set " + action.name + " to " + String(action.value)
        return text
    }
    
    private func infoLabelTextFromScheduleAction (action: AylaScheduleAction) -> String {
        var firepointString = ""
        switch action.firePoint{
        case .AtEnd:
            firepointString = "At End of schedule"
        case .AtStart:
            firepointString = "At Start of schedule"
        case .InRange:
            firepointString = "During schedule (In Range)"
        case .Unspecified:
            firepointString = "At Unspecified point"
        }
        let text = "Fires " + firepointString
        return text
    }
    
    func configure(scheduleAction: AylaScheduleAction) {
        //assert( scheduleAction != nil, "Schedule Action can not be nil")
        mainLabel.text = mainLabelTextFromScheduleAction(scheduleAction)
        infoLabel.text = infoLabelTextFromScheduleAction(scheduleAction)
        if scheduleAction.active {
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
