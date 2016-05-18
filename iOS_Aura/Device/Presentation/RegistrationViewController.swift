//
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK
import UIKit

class RegistrationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var logTextView: UITextView!
    
    enum Section :Int {
        case SameLan
        case ButtonPush
        case Display
        case SectionCount
    }
    
    /// Device model used by view controller to present this device.
    var sessionManager :AylaSessionManager?
    var candidateSameLan :AylaRegistrationCandidate?
    var candidateButtonPush :AylaRegistrationCandidate?
    var candidateDisplay :AylaRegistrationCandidate?
    
    
    let RegistrationCellId :String = "CandidateCellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
            self.sessionManager = sessionManager
        }
        else {
            print("- WARNING - session manager can't be found")
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let cancel = UIBarButtonItem(barButtonSystemItem:.Cancel, target: self, action: #selector(RegistrationViewController.cancel))
        self.navigationItem.leftBarButtonItem = cancel
        
        let refresh = UIBarButtonItem(barButtonSystemItem:.Refresh, target: self, action: #selector(RegistrationViewController.refresh))
        self.navigationItem.rightBarButtonItem = refresh

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    func cancel() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getCandidate(indexPath:NSIndexPath) -> AylaRegistrationCandidate? {
        var candidate :AylaRegistrationCandidate?
        switch indexPath.section {
        case Section.SameLan.rawValue:
            candidate = candidateSameLan;
            break
        case Section.ButtonPush.rawValue:
            candidate = candidateButtonPush;
            break
        case Section.Display.rawValue:
            candidate = candidateDisplay;
            break
        default:
            break
        }
        return candidate
    }
    
    func register(candidate :AylaRegistrationCandidate) {
        if let reg = sessionManager?.deviceManager.registration {
            updatePrompt("Registering...")
            reg.registerCandidate(candidate, success: { (AylaDevice) in
                    self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                }, failure: { (error) in
                    self.updatePrompt("Failed")
                    self.addLog(error.description)
            })
        }
        else {
            updatePrompt("Invalid registration");
        }
    }
    
    func refresh() {
        if let reg = sessionManager?.deviceManager.registration {
        
            let aGroup = dispatch_group_create()
            
            dispatch_group_enter(aGroup)
            dispatch_group_enter(aGroup)
            dispatch_group_enter(aGroup)
            
            updatePrompt("Refreshing...")
            reg.fetchCandidateWithDSN(nil, registrationType: .SameLan, success: { (candidate) in
                self.candidateSameLan = candidate
                self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(Section.SameLan.rawValue, 1)), withRowAnimation: .Automatic)
                dispatch_group_leave(aGroup)
                }, failure: { (error) in
                    self.candidateSameLan = nil;
                    self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(Section.SameLan.rawValue, 1)), withRowAnimation: .Automatic)
                    //Skip 404 for now
                    if let httpResp = error.userInfo[AylaHTTPErrorHTTPResponseKey] as? NSHTTPURLResponse {
                        if(httpResp.statusCode != 404) {
                            self.addLog("SameLan - " + error.description)
                        }
                        else {
                            self.addLog("No Same Lan candidate")
                        }
                    }
                    else {
                        self.addLog("SameLan - " + error.description)
                    }
                    dispatch_group_leave(aGroup)
                    
            })
            
            reg.fetchCandidateWithDSN(nil, registrationType: .ButtonPush, success: { (candidate) in
                self.candidateButtonPush = candidate
                self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(Section.ButtonPush.rawValue, 1)), withRowAnimation: .Automatic)
                dispatch_group_leave(aGroup)
                }, failure: { (error) in
                    self.candidateButtonPush = nil;
                    self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(Section.ButtonPush.rawValue, 1)), withRowAnimation: .Automatic)
                    
                    //Skip 404 for now
                    if let httpResp = error.userInfo[AylaHTTPErrorHTTPResponseKey] as? NSHTTPURLResponse {
                        if(httpResp.statusCode != 404) {
                            self.addLog("ButtonPush - " + error.description)
                        }
                        else  {
                            self.addLog("No Button Push candidate")
                        }
                    }
                    else {
                        self.addLog("ButtonPush - " + error.description)
                    }
            
                    dispatch_group_leave(aGroup)
            })
            
            reg.fetchCandidateWithDSN(nil, registrationType: .Display, success: { (candidate) in
                self.candidateDisplay = candidate
                self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(Section.Display.rawValue, 1)), withRowAnimation: .Automatic)
                dispatch_group_leave(aGroup)
                }, failure: { (error) in
                    self.candidateDisplay = nil;
                    self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(Section.Display.rawValue, 1)), withRowAnimation: .Automatic)
                    
                    //Skip 404 for now
                    if let httpResp = error.userInfo[AylaHTTPErrorHTTPResponseKey] as? NSHTTPURLResponse {
                        if(httpResp.statusCode != 404) {
                            self.addLog("Display - " + error.description)
                        }
                        else  {
                            self.addLog("No Display Mode candidate")
                        }
                    }
                    else {
                        self.addLog("Display - " + error.description)
                    }
                    
                    dispatch_group_leave(aGroup)
            })

            dispatch_group_notify(aGroup, dispatch_get_main_queue(), {
                self.updatePrompt(nil)
            })
        }
    }
    
    func addLog(logText: String) {
        logTextView.text = logTextView.text + "\n" + logText
    }
    
    func updatePrompt(prompt: String?) {
        self.navigationController?.navigationBar.topItem?.prompt = prompt
        addLog(prompt ?? "done")
    }
    
    
    func coordinatesFromStrings(latString: String?, lngString: String?) -> (latitude: NSNumber?, longitude: NSNumber)? {
        if latString == nil || lngString == nil || latString?.characters.count < 1 || lngString?.characters.count < 1 {
            return nil
        }
        var latitude :NSNumber
        var longitude :NSNumber
        
        if let latDouble = Double(latString!), lngDouble = Double(lngString!) {
            if case (-180...180, -180...180) = (latDouble, lngDouble) {
                longitude = NSNumber(double:lngDouble)
                latitude = NSNumber(double:latDouble)
                return (latitude, longitude)
            }
        }
        return nil
    }
    
    // MARK - Table view delegate / data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.SectionCount.rawValue
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationCellId) as? RegistrationTVCell
        if (cell != nil) {
            switch indexPath.section {
            case Section.SameLan.rawValue:
                cell?.configure(candidateSameLan)
                break
            case Section.ButtonPush.rawValue:
                cell?.configure(candidateButtonPush)
                break
            case Section.Display.rawValue:
                cell?.configure(candidateDisplay)
            default:
                cell?.configure(nil)
            }
        }
        else {
            assert(false, "\(RegistrationCellId) - reusable cell can't be dequeued'")
        }
        
        return cell!;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.SameLan.rawValue:
            return Int(candidateSameLan != nil);
        case Section.ButtonPush.rawValue:
            return Int(candidateButtonPush != nil);
        case Section.Display.rawValue:
            return Int(candidateDisplay != nil);
        default:
            return 0;
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.SameLan.rawValue:
            return "Same LAN Candidate"
        case Section.ButtonPush.rawValue:
            return "Button Push Candidate"
        case Section.Display.rawValue:
            return "Display Mode Candidate"
        default:
            return "";
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var tokenTextField = UITextField()
        var latitudeTextField = UITextField()
        var longitudeTextField = UITextField()
        
        let message = indexPath.section == Section.Display.rawValue ? "Please find the registration token and enter it below to continue\n\n You may also set the coordinates for the device's location if you wish." : "You may set the coordinates for the device's location here if you wish."
        let alert = UIAlertController(title: "Register this device?", message: message, preferredStyle: .Alert)
        let registerAction = UIAlertAction(title: "Register", style: .Default) { (action) in
            
            if let candidate = self.getCandidate(indexPath) {
                if indexPath.section == Section.Display.rawValue {
                    let token = tokenTextField.text
                    
                    if token == nil || token!.characters.count < 1 {
                        UIAlertController.alert("Error", message: "You must provide a registration token to register a Display Mode device.", buttonTitle: "OK",fromController: self)
                        return
                    }
                    
                    candidate.registrationToken = token
                }
                if let (lat, long) = self.coordinatesFromStrings(latitudeTextField.text, lngString: longitudeTextField.text){
                    candidate.lat = lat!.doubleValue
                    candidate.lng = long.doubleValue
                    let message = String(format:"Adding Latitude: %f and longitude: %f to registration candidate", lat!.doubleValue, long.doubleValue)
                    print(message)
                    self.addLog(message)
                }
                self.register(candidate)
            }
            else {
                self.updatePrompt("Internal error")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        if indexPath.section == Section.Display.rawValue {
            alert.addTextFieldWithConfigurationHandler({ (textField) in
                textField.placeholder = "Registration Token"
                textField.tintColor = UIColor.auraLeafGreenColor()
                tokenTextField = textField
            })
        }
        alert.addTextFieldWithConfigurationHandler({ (textField) in
            textField.placeholder = "Latitude (optional)"
            textField.tintColor = UIColor.auraLeafGreenColor()
            textField.keyboardType = UIKeyboardType.DecimalPad
            latitudeTextField = textField
        })
        alert.addTextFieldWithConfigurationHandler({ (textField) in
            textField.placeholder = "Longitude (optional)"
            textField.tintColor = UIColor.auraLeafGreenColor()
            textField.keyboardType = UIKeyboardType.DecimalPad
            longitudeTextField = textField
        })
        
        alert.addAction(cancelAction)
        alert.addAction(registerAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
