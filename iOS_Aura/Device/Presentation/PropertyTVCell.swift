//
//  PropertyTVCell.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class PropertyTVCell: UITableViewCell {
    
    @IBOutlet weak var propertySwitch: UISwitch!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    var property: AylaProperty?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configure(property: AylaProperty) {
        self.property = property
        if let baseType = self.property?.baseType{
            //  Make switch visible only if property is a boolean
            //  Disable switch if property is from_device
            if baseType == "boolean"{
                if let direction = self.property?.direction {
                    propertySwitch?.enabled = direction == "input" ? true : false
                    if let value = self.property?.datapoint.value {
                        propertySwitch?.on = value as! Bool
                    }
                }
                propertySwitch?.hidden = false
            }
            else {
                propertySwitch?.hidden = true
            }
        }
        nameLabel.text = self.property?.name
        infoLabel?.text = String.localizedStringWithFormat("%@ - %@", (self.property?.direction)!, (self.property?.baseType)!)
        if let value = self.property?.datapoint.value {
            valueLabel.text = "\(value)"
        }
        else {
            valueLabel.text = "(null)"
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func switchTapped(sender: UISwitch) {
        sender.enabled = false
        print(sender.on ? "Switch turned on" : "Switch turned Off")
        
        // Check for previous value of property
        if let boolValue = self.property?.datapoint.value {
            
            // Set up datapoint for new value
            let newVal = boolValue as! NSNumber == 1 ? NSNumber(int:0) : NSNumber(int:1)
            let dpParams = AylaDatapointParams()
            dpParams.value = newVal
            
            // Create Datapoint
            self.property!.createDatapoint(dpParams, success: { (datapoint) -> Void in
                print("Created datapoint.")
                sender.enabled = true
                }, failure: { (error) -> Void in
                    sender.enabled = true
                    print("Create Datapoint Failed.")
            })
        }
    }
}