//
//  NodeRegistrationViewController.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 6/7/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import PDKeychainBindingsController
import iOS_AylaSDK
import UIKit


class NodeRegistrationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logTextView: AuraConsoleTextView!
    
    enum Section :Int {
        case TargetGateway
        case Nodes
        case SectionCount
    }
    
    var sessionManager :AylaSessionManager?
    
    var targetGateway : AylaDeviceGateway?
    var candidateNodeList : [AylaRegistrationCandidate] = []
    
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
        
        // Add tap recognizer to dismiss keyboard.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        self.logTextView.backgroundColor = UIColor.whiteColor()
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
        case Section.Nodes.rawValue:
            candidate = candidateNodeList[indexPath.row];
            break
        default:
            break
        }
        return candidate
    }
    
    func register(candidate :AylaRegistrationCandidate) {
        if let reg = sessionManager?.deviceManager.registration {
            updatePrompt("Registering Node...")
            reg.registerCandidate(candidate, success: { (AylaDevice) in
                self.updatePrompt("Successfully Registered Device.")
                
                // Un-comment to cause app to back out after single node registration.
                //self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                }, failure: { (error) in
                    self.updatePrompt("Registration Failed")
                    self.addLog(error.description)
            })
        }
        else {
            updatePrompt("Invalid registration");
        }
    }
    
    func refresh() {
        targetGateway?.fetchCandidatesWithSuccess({ (nodes) in
            self.candidateNodeList = nodes
            self.tableView.reloadData()
            }, failure: { (error) in
                self.candidateNodeList = []
                self.addLog("No node candidates found")
                self.addLog(error.localizedDescription)
        })
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
        if let latDouble = Double(latString!), lngDouble = Double(lngString!) {
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
            let cell = tableView.dequeueReusableCellWithIdentifier(RegistrationCellId) as? RegistrationTVCell
            if (cell != nil) {
                switch indexPath.section {
                case Section.Nodes.rawValue:
                    cell?.configure(candidateNodeList[indexPath.row])
                    break
                case Section.TargetGateway.rawValue:
                    cell?.nameLabel.text = self.targetGateway!.productName
                    cell?.dsnLabel.text = self.targetGateway!.dsn! + " (" + self.targetGateway!.oemModel! + ")"
                default:
                    cell?.configure(nil)
                }
            } else {
                assert(false, "\(RegistrationCellId) - reusable cell can't be dequeued'")
            }
            return cell!;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.TargetGateway.rawValue:
            return 1
        case Section.Nodes.rawValue:
            return candidateNodeList.count;
        default:
            return 0;
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 96.0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.TargetGateway.rawValue:
            return "Gateway Details"
        case Section.Nodes.rawValue:
            return "Candidate Nodes"
        default:
            return "";
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == Section.TargetGateway.rawValue{
            self.joinWindowAlertForIndexPath(indexPath)
        } else {
            self.registerAlertForIndexPath(indexPath)
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func joinWindowAlertForIndexPath(indexPath: NSIndexPath){
        let defaultDuration : UInt = 200
        var durationTextField = UITextField()

        let message = String(format:"Attempt to open a join window for this gateway?\n\nNote: Gateway must have 'join_enable' property for this to succeed.\n\n(Default window duration is %u seconds.)", defaultDuration)
        let alert = UIAlertController(title: "Open a join window?", message: message, preferredStyle: .Alert)
        let joinWindowAction = UIAlertAction(title: "Open", style: .Default) { (action) in
            var duration: UInt
            if durationTextField.text == nil || durationTextField.text == "" {
                duration = defaultDuration
            } else {
                duration = UInt(durationTextField.text!)!
            }
            self.targetGateway?.openRegistrationJoinWindow(duration, success: { 
                self.addLog("Success.")
                }, failure: { (error) in
                    self.addLog("Failed to open Join Window")
                    self.addLog(error.description)
            })
            self.addLog("Opening Join Window...")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        alert.addTextFieldWithConfigurationHandler({ (textField) in
            textField.placeholder = "Custom Duration (optional)"
            textField.tintColor = UIColor.auraLeafGreenColor()
            textField.keyboardType = UIKeyboardType.NumberPad
            durationTextField = textField
        })
        
        alert.addAction(cancelAction)
        alert.addAction(joinWindowAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func registerAlertForIndexPath(indexPath: NSIndexPath){

        let alert = UIAlertController(title: "Register this device?", message: nil, preferredStyle: .Alert)
        let registerAction = UIAlertAction(title: "Register", style: .Default) { (action) in
            
            if let candidate = self.getCandidate(indexPath) {
                candidate.registrationType = AylaRegistrationType.Node
                self.register(candidate)
            }
            else {
                self.updatePrompt("Internal error")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        alert.addAction(cancelAction)
        alert.addAction(registerAction)
        presentViewController(alert, animated: true, completion: nil)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
