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
     2) Cancel
     
     - parameter viewController: The view controller which presents this action controller.
     */
    func presentActions(presentingViewController viewController: UIViewController){
        
        // Don't update file property by inputing text
        if property.baseType == "file" {
            return
        }
    
        let alertController = UIAlertController(title: property.name, message: nil, preferredStyle: .Alert)

        let updateAction = UIAlertAction(title: "Update Value", style: .Default) { (_) in
            let textField = alertController.textFields![0] as UITextField
            let dpParams = AylaDatapointParams()
            if let val = self.valueFromString(textField.text!) {
                dpParams.value = val
                self.property.createDatapoint(dpParams, success: { (datapoint) -> Void in
                    print("Created datapoint.")
                    }, failure: { (error) -> Void in
                        error.displayAsAlertController()
                })
            }
        }
        updateAction.enabled = false
        
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
        alertController.addAction(cancelAction)
        
        viewController.presentViewController(alertController, animated: true, completion: { () -> Void in
            
        })
    }
    
    /**
     A method that forwards a PropertyModelAction to the PropertyModel delegate
     
     - parameter action: A PropertyModelAction sent to the delegate
    */
    func chosenAction(action: PropertyModelAction){
        self.delegate?.propertyModel(self, didSelectAction: action)
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
    
    func previewAction(presentingViewController viewController: UIViewController) {
        if property.datapoint is AylaDatapointBlob {
            let blob = property.datapoint as! AylaDatapointBlob
            let fileName = (blob.value as! NSString).lastPathComponent
            // delete the `.json` suffix
            let filePath = NSURL(fileURLWithPath: "\(cachePath()!)/\(fileName)").URLByDeletingPathExtension!
            
            if NSFileManager.defaultManager().fileExistsAtPath(filePath.path!) {
                preview(filePath, presentingViewController: viewController)
                return
            }
            
            let alertController = UIAlertController(title: nil, message: "Please wait...\n\n", preferredStyle: UIAlertControllerStyle.Alert)
            let spinnerIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            spinnerIndicator.center = CGPointMake(135.0, 65.5)
            spinnerIndicator.color = UIColor.blackColor()
            spinnerIndicator.startAnimating()
            alertController.view.addSubview(spinnerIndicator)
            
            let task = blob.downloadToFile(filePath,
                progress: { (progress) in
                    dispatch_async(dispatch_get_main_queue(), { 
                        alertController.message = "Please wait...\(progress.localizedDescription)\n\n"
                    })
                },
                success: { (url) in
                    alertController.dismissViewControllerAnimated(false, completion: nil)
                    
                    self.preview(url, presentingViewController: viewController)
                },
                failure: { (error) in
                    spinnerIndicator.removeFromSuperview()
                    alertController.message = error.localizedDescription
                    print(error)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) in
                task.cancel()
            })
            alertController.addAction(cancelAction)
            viewController.presentViewController(alertController, animated: false, completion: nil)
        }
        else {
            print("preview is only for file property")
        }
    }
    
    func cachePath() -> String? {
        if let cachePath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first {
            var isDir: ObjCBool = false
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(cachePath, isDirectory: &isDir) == false && !isDir {
                try! fileManager.createDirectoryAtPath(cachePath, withIntermediateDirectories: false, attributes: nil)
            }
            return cachePath
        }
        
        return nil
    }
    
    func preview(fileURL: NSURL, presentingViewController viewController: UIViewController) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        viewController.presentViewController(activityController, animated: true, completion: nil)
    }
}
