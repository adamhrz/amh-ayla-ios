//
//  PropertyModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 3/11/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK

protocol PropertyModelDelegate: class {
    func propertyModel(model:PropertyModel, didSelectAction action:PropertyModelAction)
}

public enum PropertyModelAction : Int {
    case Details // details
}

class PropertyModel: NSObject, UITextFieldDelegate {
    
    /// Property presented by this model
    var property: AylaProperty
    
    /// Delegate of current property model
    weak var delegate :PropertyModelDelegate?
    
    required init(property:AylaProperty, presentingViewController: UIViewController?) {
        self.property = property
        super.init()
    }
    
    /**
     Use this method to present an UIAlertController with defined options:
     1) Update with input value
     2) Switch to detail page
     3) Cancel
     
     - parameter viewController: The view controller which presents this action controller.
     */
    func presentActions(presentingViewController viewController: UIViewController){
    
        let alertController = UIAlertController(title: property.name, message: nil, preferredStyle: .Alert)

        let updateAction = UIAlertAction(title: "Update Value", style: .Default) { (_) in
            let textField = alertController.textFields![0] as UITextField
            let dpParams = AylaDatapointParams()
            if let val = self.valueFromString(textField.text!) {
                dpParams.value = val
                self.property.createDatapoint(dpParams, success: { (datapoint) -> Void in
                    print("Created datapoint.")
                    }, failure: { (error) -> Void in
                        
                })
            }
        }
        updateAction.enabled = false
        
        let detailAction = UIAlertAction(title: "Details", style: .Default) { (_) in
            self.delegate?.propertyModel(self, didSelectAction: .Details)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (alertAction) -> Void in
            NSNotificationCenter.defaultCenter().removeObserver(alertController.textFields![0])
            alertController.textFields![0].resignFirstResponder()
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in

            textField.placeholder = "baseType: \(self.property.baseType)"
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                if self.valueFromString(textField.text) != nil {
                    updateAction.enabled = true
                }
                else {
                    updateAction.enabled = false
                }
            }
        }
        
        alertController.addAction(updateAction)
        alertController.addAction(detailAction)
        alertController.addAction(cancelAction)
        
        viewController.presentViewController(alertController, animated: true, completion: { () -> Void in
            
        })
    }
    
    /**
     A helpful method to validate and transfer input string value
     
     - parameter str: The value in string
     
     - returns: Value in right type. Returns nil if input value is invalid.
     */
    func valueFromString(str:String?) -> AnyObject? {
    
        if str == nil {
            return nil;
        }
        else if self.property.baseType == "string" || self.property.baseType == "file" {
            return str;
        }
        else if self.property.baseType == "integer" {
            if let intValue = Int(str!) {
                return NSNumber(integer: intValue)
            }
        }
        else if self.property.baseType == "boolean" {
            if str == "1" { return NSNumber(int: 1) }
            if str == "0" { return NSNumber(int: 0) }
            return nil
        }
        else {
            if let doubleValue = Double(str!) {
                return NSNumber(double: doubleValue)
            }
        }
        
        return nil
    }
}
