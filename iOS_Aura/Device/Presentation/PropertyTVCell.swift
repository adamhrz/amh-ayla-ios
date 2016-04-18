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
    
    @IBOutlet weak var valueView: UIView!
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var propertySwitch: UISwitch!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    var nameTapRecognizer: UITapGestureRecognizer!
    var valueTapRecognizer: UITapGestureRecognizer!
    weak var parentPropertyListViewModel: PropertyListViewModel!
    
    var property: AylaProperty?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //Set up tap recognizers for each side of the cell
        nameTapRecognizer = UITapGestureRecognizer(target:self, action:#selector(PropertyTVCell.nameTapped(_:)))
        nameTapRecognizer.numberOfTapsRequired = 1
        nameView.userInteractionEnabled = true
        nameView.addGestureRecognizer(nameTapRecognizer)
        
        valueTapRecognizer = UITapGestureRecognizer(target:self, action: #selector(PropertyTVCell.valueTapped(_:)))
        valueTapRecognizer.numberOfTapsRequired = 1
        valueView.userInteractionEnabled = true
        valueView.addGestureRecognizer(valueTapRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func nameTapped (sender: UITapGestureRecognizer){
        self.parentPropertyListViewModel.showDetailsForProperty(sender, property:self.property!)
    }
    func valueTapped (sender: UITapGestureRecognizer){
        self.parentPropertyListViewModel.showValueAlertForProperty(sender, property:self.property!)
    }
    
    func configure(property: AylaProperty) {
        self.property = property
        if let baseType = self.property?.baseType{
            //  Make switch visible only if property is a boolean
            //  Disable switch if property is from_device
            if baseType == "boolean"{
                if let direction = self.property?.direction {
                    propertySwitch?.enabled = direction == "input" ? true : false
                    if let value = self.property?.datapoint?.value {
                        propertySwitch?.on = value as! Bool
                    }
                    else {
                        propertySwitch?.on = false
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
        
        let value = String.stringFromStringNumberOrNil(self.property?.datapoint?.value)
        valueLabel.text = value
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func switchTapped(sender: UISwitch) {
        sender.enabled = false
        valueTapRecognizer.enabled = false
        print(sender.on ? "Switch turned on" : "Switch turned Off")
        
        // Code to reenable cell after datapoint call completes.
        func reenableCell() {
            sender.enabled = true
            valueTapRecognizer.enabled = true
        }
        
        // Check for previous value of property. If there is no previous value, create datapoint with value (1).
        var boolValue = NSNumber(int: 0)
        if let curVal = self.property?.datapoint?.value {
            boolValue = curVal as! NSNumber
        }
            
        // Set up datapoint for new value
        let newVal = boolValue == 1 ? NSNumber(int:0) : NSNumber(int:1)
        let dpParams = AylaDatapointParams()
        dpParams.value = newVal
        
        // Create Datapoint
        self.property!.createDatapoint(dpParams, success: { (datapoint) -> Void in
            print("Created datapoint.")
            reenableCell()
            }, failure: { (error) -> Void in
                reenableCell()
                print("Create Datapoint Failed.")
        })
    }
}