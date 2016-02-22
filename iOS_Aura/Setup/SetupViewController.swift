//
//  SetupViewController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class SetupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    static let CellId: String = "SetupCellId"
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var controlPanel: UIView!
    
    var setup: AylaSetup
    var alert: UIAlertController? {
        willSet(newAlert) {
            if let oldAlert = alert {
                oldAlert .dismissViewControllerAnimated(false, completion: nil)
            }
        }
    }
    var currentTask: AylaConnectTask?
    var scanResults :AylaWifiScanResults?
    var token: String?
    
    required init?(coder aDecoder: NSCoder)
    {
        // Init setup
        setup = AylaSetup(coreManager: AylaCoreManager.sharedManager())
        
        super.init(coder: aDecoder);
        
        // Monitor connectivity
        self.monitorDeviceConnectivity()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        let refresh = UIBarButtonItem(barButtonSystemItem:.Refresh, target: self, action: Selector("refresh"))
        self.navigationItem.rightBarButtonItem = refresh
        
        attemptToConnect()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updatePrompt(prompt: String?) {
        self.navigationController?.navigationBar.topItem?.prompt = prompt
    }
    
    func monitorDeviceConnectivity() {
        // Add observer to setup device connection status.
        setup.addObserver(self, forKeyPath: "setupDevice.connected", options: .New, context: nil)
    }
    
    func refresh() {
        
        // Clean scan results
        scanResults = nil
        tableView.reloadData()
        
        attemptToConnect()
    }
    
    func attemptToConnect() {

        updatePrompt("loading...")
        
        currentTask = setup.connectToNewDevice({ (setupDevice) -> Void in
            self.addDescription("Find device: \(setupDevice.dsn)")
            self.fetchApList()
            }) { (error) -> Void in
            self.updatePrompt("No device found")
            self.addDescription("Unable to find device: \(error.description)")
        }
    }

    func fetchApList() {
        updatePrompt("loading...")
        currentTask = setup.fetchDeviceAccessPoints({ (scanResults) -> Void in
            self.updatePrompt(self.setup.setupDevice?.dsn ?? "")
            self.scanResults = scanResults
            self.tableView.reloadData()
            
            }, failure: { (error) -> Void in
                self.updatePrompt("Failed")
                self.addDescription("Fetch ap results: \(error.description)")
        })
    }
    
    func connectToSSID(ssid: String, password: String?) {
    
        // Create a random token.
        token = "AToken"
        
        self.updatePrompt("Connecting device to SSID...")
        self.setup.connectDeviceToServiceWithSSID(ssid, password: password, setupToken: token!, latitude: 0.0, longtitude: 0.0, success: { () -> Void in
            
            // Succeeded, go confirming.
            self.addDescription("Connected to \(ssid)")
            
            // Call to confirm connection.
            self.confirmConnectionToService()
            
            }) { (error) -> Void in
            self.updatePrompt("Failed")
            self.displayError(error)
        }
    }
    
    func confirmConnectionToService() {
        self.updatePrompt("Confirming device status ...")
        self.setup.confirmDeviceConnectedWithTimeout(30.0, dsn:(self.setup.setupDevice?.dsn)!, setupToken:token!, success: { () -> Void in
            self.updatePrompt("Succeeded")
            }) { (error) -> Void in
            self.displayError(error)
        }
    }
    
    /**
     Use this method to add a description to description text view.
     */
    func addDescription(description: String) {
        descriptionTextView.text = "\(descriptionTextView.text) \n\(description)"
    }
    
    func displayError(error:NSError) {
    
        if let currentAlert = alert {
            currentAlert.dismissViewControllerAnimated(false, completion: nil)
        }
        
        let alertController = UIAlertController(title: "Error", message: "\(error.userInfo[AylaRequestErrorResponseJsonKey])", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Got it", style: .Cancel, handler: nil))
        
        alert = alertController
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.setup.exit()
        }
    }
    
    deinit {
        self.setup.removeObserver(self, forKeyPath: "connected")
    }
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        if let result = scanResults?.results[indexPath.row] {
            
            let alertController = UIAlertController(title: "Password Required", message: "Please input password for \"\(result.ssid)\".", preferredStyle: .Alert)
            
            let connect = UIAlertAction(title: "Connect", style: .Default) { (_) in
                let password = alertController.textFields![0] as UITextField
                self.connectToSSID(result.ssid, password: password.text)
            }
            connect.enabled = false
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in
                let password = alertController.textFields![0] as UITextField
                password.resignFirstResponder()
            }
            
            alertController.addTextFieldWithConfigurationHandler { (textField) in
                textField.placeholder = "SSID password"
                NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                    connect.enabled = textField.text != ""
                }
            }
            alertController.addAction(connect)
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
            // Call to wake up main run loop
            CFRunLoopWakeUp(CFRunLoopGetCurrent());
        }
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        if let result = scanResults?.results[indexPath.row] {
            let connectAction = UITableViewRowAction(style: .Normal, title:"\(result.signal)" ) { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
                //TODO: edit the row at indexPath here
            }
            connectAction.backgroundColor = UIColor.darkGrayColor()
            
            return [connectAction]
        }
        
        return nil
    }
    
    // MARK: - Table view datasource
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let results = self.scanResults?.results as [AylaWifiScanResult]!
            
        let result = results[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(SetupViewController.CellId)
            
        cell?.textLabel!.text = result.ssid
        cell!.selectionStyle = UITableViewCellSelectionStyle.None
            
        return cell!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanResults?.results.count ?? 0
    }
    
    // MARK: - KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if object === self.setup.setupDevice as? AnyObject {
            if let device = object as? AylaSetupDevice {
                if !device.connected {
                    self.updatePrompt("Lost Connectivity To Device")
                }
            }
        }
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
