//
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import PDKeychainBindingsController
import iOS_AylaSDK
import UIKit
import Ayla_LocalDevice_SDK

class RegistrationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CellButtonDelegate, CellSelectorDelegate, AylaDeviceManagerListener, AylaDeviceListener {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var logTextView: AuraConsoleTextView!
    
    /// Segue id to property view
    let segueIdToNodeRegistrationView :String = "toNodeRegistrationPage"
    
    enum Section :Int {
        case SameLan
        case ButtonPush
        case GatewayNode
        case Manual
        case LocalDevice
        case SectionCount
    }
    
    enum SelectorMode :Int {
        case Display
        case DSN
        case APMode
        case Manual
        case SectionCount
    }
    
    var selectorIndex : Int!
    
    /// Reference to our current AylaSessionManager instance.
    var sessionManager :AylaSessionManager?
    
    /// Reference to our current AylaDeviceManager instance.
    var deviceManager : AylaDeviceManager?
    
    /// Reference to our current list of devices.
    var devices: [AylaDevice] = []
    
    var candidateSameLan :AylaRegistrationCandidate?
    var candidateButtonPush :AylaRegistrationCandidate?
    var candidateManual :AylaRegistrationCandidate?
    var gateways : [AylaDeviceGateway?] = []
    var discoveredLocalDevices = [AylaRegistrationCandidate]()

    
    let RegistrationCellId :String = "CandidateCellId"
    
    let RegistrationModeSelectorCellId :String = "ModeSelectorCellId"
    
    let RegistrationDSNCellId :String = "CandidateDSNCellId"
    let RegistrationDisplayCellId :String = "CandidateDisplayCellId"
    let RegistrationAPModeCellId :String = "CandidateAPModeCellId"
    let RegistrationManualCellId :String = "CandidateManualCellId"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
            self.sessionManager = sessionManager
            self.deviceManager = sessionManager.deviceManager
            // Add self as device manager listener
            self.deviceManager!.addListener(self)
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
        self.selectorIndex = 0
        
        // Add tap recognizer to dismiss keyboard.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        self.logTextView.backgroundColor = UIColor.whiteColor()
    }
    
    func updateGatewaysList() {
        self.devices = self.deviceManager!.devices.values.map({ (device) -> AylaDevice in
            return device as! AylaDevice
        })
        gateways = []
        if self.devices.count > 0 {
            for device in self.devices {
                if device.isKindOfClass(AylaDeviceGateway) {
                    gateways.append((device as! AylaDeviceGateway))
                }
            }
        }
        self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(Section.GatewayNode.rawValue, 1)), withRowAnimation: .Automatic)
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
        switch Section(rawValue:indexPath.section)! {
        case .SameLan:
            candidate = candidateSameLan;
            break
        case .ButtonPush:
            candidate = candidateButtonPush;
            break
        case .Manual:
            candidate = candidateManual;
            break
        case .LocalDevice:
            candidate = discoveredLocalDevices[indexPath.row]
        default:
            break
        }
        return candidate
    }
    
    func register(candidate :AylaRegistrationCandidate) {
        if candidate.registrationType.rawValue == AylaRegistrationTypeLocal {
            guard let localDeviceManager = AylaNetworks.shared().getPluginWithId(AuraLocalDeviceManager.PLUGIN_ID_LOCAL_DEVICE) as? AuraLocalDeviceManager
                else {
                    self.updatePrompt("No Local Device Manager found")
                    return
            }
            guard let sessionManager = self.sessionManager
                else {
                    self.updatePrompt("No Session Manager found")
                    return
            }
            updatePrompt("Registering...")
            localDeviceManager.registerLocalDevice(candidate, sessionManager: sessionManager, success: { (localDevice) in
                print("Registered device \(localDevice)")
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                }, failure: { (error) in
                    self.updatePrompt("Failed to register Local Device")
                    self.addLog(error.description)
            })
            return
        }
        if let reg = sessionManager?.deviceManager.registration {
            updatePrompt("Registering...")
            reg.registerCandidate(candidate, success: { (AylaDevice) in
                if candidate.registrationType == AylaRegistrationType.APMode {
                    PDKeychainBindings.sharedKeychainBindings().removeObjectForKey(AuraDeviceSetupTokenKeychainKey)
                    PDKeychainBindings.sharedKeychainBindings().removeObjectForKey(AuraDeviceSetupDSNKeychainKey)
                    print("Removing AP Mode Device details from storage")
                }
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
        self.updateGatewaysList()
        if let reg = sessionManager?.deviceManager.registration {
        
            let aGroup = dispatch_group_create()
            
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
            self.candidateManual = AylaRegistrationCandidate()
            self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(Section.Manual.rawValue, 1)), withRowAnimation: .Automatic)

            dispatch_group_notify(aGroup, dispatch_get_main_queue(), {
                self.updatePrompt(nil)
            })
        }
        guard let localDeviceManager = AylaNetworks.shared().getPluginWithId(AuraLocalDeviceManager.PLUGIN_ID_LOCAL_DEVICE) as? AuraLocalDeviceManager
            else {
                return
        }
        localDeviceManager.findLocalDevicesWithHint(nil, timeout: 5000, success: { (foundDevices) in
            self.discoveredLocalDevices = foundDevices
            self.tableView.reloadData()
            }) { (error) in
                self.addLog("Error fetching local candidates: \(error)")
        }
    }
    
    func addLog(logText: String) {
        logTextView.text = logTextView.text + "\n" + logText
    }
    
    func updatePrompt(prompt: String?) {
        self.navigationController?.navigationBar.topItem?.prompt = prompt
        addLog(prompt ?? "done")
    }
    
    
    func verifyCoordinateStringsValid(latString: String?, lngString: String?) -> Bool {
        if latString == nil || lngString == nil || latString?.characters.count < 1 || lngString?.characters.count < 1 {
            return false
        }
        if let latDouble = Double(latString!), let lngDouble = Double(lngString!) {
            if case (-180...180, -180...180) = (latDouble, lngDouble) {
                return true
            }
            else {
                return false
            }
        }
        return false
    }
    
    // MARK - Table view delegate / data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.SectionCount.rawValue
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == Section.Manual.rawValue{
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationModeSelectorCellId) as? RegistrationModeSelectorTVCell
                if (cell != nil) {
                    cell?.selectorDelegate = self
                    cell?.modeSelector.tintColor = UIColor.auraLeafGreenColor()
                } else {
                    assert(false, "\(RegistrationCellId) - reusable cell can't be dequeued'")
                }
                return cell!;
            case 1:
                
                switch self.selectorIndex!{
                case SelectorMode.Display.rawValue:
                    let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationDisplayCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    return cell!;
                case SelectorMode.DSN.rawValue:
                    let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationDSNCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    return cell!;
                case SelectorMode.APMode.rawValue:
                    let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationAPModeCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    
                    if let dsn = PDKeychainBindings.sharedKeychainBindings().stringForKey(AuraDeviceSetupDSNKeychainKey) {
                        cell?.dsnField!.text = dsn
                    }
                    if let token = PDKeychainBindings.sharedKeychainBindings().stringForKey(AuraDeviceSetupTokenKeychainKey) {
                        cell?.regTokenField!.text = token
                    }
 
                    return cell!;
                case SelectorMode.Manual.rawValue:
                    let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationManualCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    return cell!;
                default:
                    let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationManualCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    return cell!;
                }

            default:
                let cell = UITableViewCell()
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationCellId) as? RegistrationTVCell
        
            if (cell != nil) {
                switch Section(rawValue: indexPath.section)! {
                case .SameLan:
                    cell?.configure(candidateSameLan)
                    break
                case .ButtonPush:
                    cell?.configure(candidateButtonPush)
                    break
                case .GatewayNode:
                    if let gateway = gateways[indexPath.row] {
                    cell?.nameLabel.text = gateway.productName
                    cell?.dsnLabel.text = gateway.dsn
                    }
                case .LocalDevice:
                    let registrationCandidate = discoveredLocalDevices[indexPath.row]
                    cell?.configure(registrationCandidate)
                default:
                    cell?.configure(nil)
                }
            } else {
                assert(false, "\(RegistrationCellId) - reusable cell can't be dequeued'")
            }
            return cell!;
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .SameLan:
            return Int(candidateSameLan != nil);
        case .ButtonPush:
            return Int(candidateButtonPush != nil);
        case .GatewayNode:
            return gateways.count
        case .Manual:
            return 2;
        case .LocalDevice:
            return discoveredLocalDevices.count
        default:
            return 0;
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Section.Manual.rawValue {
            switch indexPath.row{
            case 0:
                return 65.0
            case 1:
                return 150.0
            default:
                return 0.0
            }
        } else {
            return 96.0
        }
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .SameLan:
            return "Same LAN Candidate"
        case .ButtonPush:
            return "Button Push Candidate"
        case .GatewayNode:
            return "Add Node to Gateway"
        case .Manual:
            return "Enter Candidate Details Manually"
        case .LocalDevice:
            return "Discovered Local Devices"
        default:
            return "";
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == Section.Manual.rawValue{
            
        } else if indexPath.section == Section.GatewayNode.rawValue {
            self.performSegueWithIdentifier(segueIdToNodeRegistrationView, sender: gateways[indexPath.row])
        } else {
            self.registerAlertForIndexPath(indexPath)
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func registerAlertForIndexPath(indexPath: NSIndexPath){
        //var tokenTextField = UITextField()
        var latitudeTextField = UITextField()
        var longitudeTextField = UITextField()
        
        let message = selectorIndex == SelectorMode.Display.rawValue ? "" : "You may manually set the coordinates for the device's location here if you wish."
        let alert = UIAlertController(title: "Register this device?", message: message, preferredStyle: .Alert)
        let registerAction = UIAlertAction(title: "Register", style: .Default) { (action) in
            
            if let candidate = self.getCandidate(indexPath) {
                let valid = self.verifyCoordinateStringsValid(latitudeTextField.text, lngString: longitudeTextField.text)
                if valid {
                    candidate.lat = latitudeTextField.text
                    candidate.lng = longitudeTextField.text
                    let message = String(format:"Adding Latitude: %@ and longitude: %@ to registration candidate", candidate.lat!, candidate.lng!)
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
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        if selectorIndex != SelectorMode.Display.rawValue {
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
        }
        alert.addAction(cancelAction)
        alert.addAction(registerAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - CellButtonDelegate
    func cellButtonPressed(cell: UITableViewCell){
        switch selectorIndex {
        case SelectorMode.Display.rawValue:
            let regCell = cell as! RegistrationManualTVCell
            let regToken = regCell.regTokenField!.text
            if regToken == nil || regToken!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide a registration token to register a Display Mode device.", buttonTitle: "OK",fromController: self)
                return
            }
            let newCandidate = AylaRegistrationCandidate()
            newCandidate.registrationType = AylaRegistrationType.Display
            newCandidate.registrationToken = regToken
            candidateManual = newCandidate
        case SelectorMode.DSN.rawValue:
            let regCell = cell as! RegistrationManualTVCell
            let dsn = regCell.dsnField!.text
            if dsn == nil || dsn!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide a DSN in order to register a DSN device.", buttonTitle: "OK",fromController: self)
                return
            }
            let deviceDict = ["device":["dsn":dsn!]]
            let newCandidate = AylaRegistrationCandidate(dictionary: deviceDict)
            print("Candidate DSN: %@", newCandidate.dsn)
            newCandidate.registrationType = AylaRegistrationType.Dsn
            candidateManual = newCandidate
        case SelectorMode.APMode.rawValue:
            let regCell = cell as! RegistrationManualTVCell
            let setupToken = regCell.regTokenField!.text
            if setupToken == nil || setupToken!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide the setup token generated during Wi-Fi Setup in order to register an AP Mode device.", buttonTitle: "OK",fromController: self)
                return
            }
            let dsn = regCell.dsnField!.text
            if dsn == nil || dsn!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide a DSN in order to register a DSN device.", buttonTitle: "OK",fromController: self)
                return
            }
            let deviceDict = ["device":["dsn":dsn!]]
            let newCandidate = AylaRegistrationCandidate(dictionary: deviceDict)
            newCandidate.setupToken = setupToken
            print("Candidate setupToken: %@", newCandidate.setupToken)
            newCandidate.registrationType = AylaRegistrationType.APMode
            candidateManual = newCandidate

        case SelectorMode.Manual.rawValue:
            let regCell = cell as! RegistrationManualTVCell
            let dsn = regCell.dsnField!.text
            if dsn == nil || dsn!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide a DSN in order to find and register a candidate device this way.", buttonTitle: "OK",fromController: self)
                return
            }
            
            var regToken = regCell.regTokenField!.text
            
            if regToken != nil && regToken!.characters.count < 1 {
                regToken = nil
            }
            
            if let reg = sessionManager?.deviceManager.registration {
                let aGroup = dispatch_group_create()
                dispatch_group_enter(aGroup)
                reg.fetchCandidateWithDSN(dsn, registrationType: .SameLan, success: { (candidate) in
                    
                    candidate.registrationToken = regToken
                    self.candidateManual = candidate
                    
                    }, failure: { (error) in
                        self.candidateManual = nil;
                        UIAlertController.alert("Error", message: "Could not find a candidate device with that DSN.", buttonTitle: "OK",fromController: self)
                        //Skip 404 for now
                        if let httpResp = error.userInfo[AylaHTTPErrorHTTPResponseKey] as? NSHTTPURLResponse {
                            if(httpResp.statusCode != 404) {
                                self.addLog("SameLan - " + error.description)
                            }
                            else {
                                self.addLog("No Same Lan candidate for this DSN")
                            }
                        }
                        else {
                            self.addLog("SameLan - " + error.description)
                        }
                        dispatch_group_leave(aGroup)
                })
                dispatch_group_notify(aGroup, dispatch_get_main_queue(), {
                    self.updatePrompt(nil)
                })
            }
        default:
            return
        }
        self.registerAlertForIndexPath(self.tableView.indexPathForCell(cell)!)
    }
    // MARK: - CellSelectorDelegate
    func cellSelectorPressed(cell: UITableViewCell, control:UISegmentedControl){
        self.selectorIndex = control.selectedSegmentIndex
        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: Section.Manual.rawValue)], withRowAnimation: .None)
    }
    
    /**
     Call to dismiss keyboard.
     */
    func dismissKeyboard() {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdToNodeRegistrationView {
            let vc = segue.destinationViewController as! NodeRegistrationViewController
            vc.targetGateway = (sender as! AylaDeviceGateway)
        }
    }
    
    // MARK - device manager listener
    func deviceManager(deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : NSError]) {
        print("Init complete")
        self.updateGatewaysList()
    }
    
    func deviceManager(deviceManager: AylaDeviceManager, didInitFailure error: NSError) {
        print("Failed to init: \(error)")
    }
    
    func deviceManager(deviceManager: AylaDeviceManager, didObserveDeviceListChange change: AylaDeviceListChange) {
        print("Observe device list change")
        if change.addedItems.count > 0 {
            for device:AylaDevice in change.addedItems {
                device.addListener(self)
            }
        }
        else {
            // We don't remove self as listener from device manager removed devices.
        }
        
        self.updateGatewaysList()
    }
    
    func deviceManager(deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState) {
        print("Change in deviceManager state: new state \(newState), was \(oldState)")
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        if change.isKindOfClass(AylaDeviceChange) {
            // Not a good long term update strategy
            self.updateGatewaysList()
        }
    }
    
    func device(device: AylaDevice, didFail error: NSError) {
        // Device errors are not handled here.
    }
}
