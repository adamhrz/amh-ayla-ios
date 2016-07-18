//
//  ScheduleEditorActionTableViewCell.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleEditorActionTableViewCell : UITableViewCell {
    
    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var actionActiveLabel: UILabel!

    
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
    
    private func configure(scheduleAction: AylaScheduleAction) {
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
    
}
