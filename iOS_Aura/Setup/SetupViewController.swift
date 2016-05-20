//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class SetupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /// Setup cell id
    static let CellId: String = "SetupCellId"
    
    /// Description view to display status
    @IBOutlet weak var descriptionTextView: UITextView!
    
    /// Table view of scan results
    @IBOutlet weak var tableView: UITableView!
    
    /// A reserved view for future use.
    @IBOutlet weak var controlPanel: UIView!
    
    /// AylaSetup instance used by this setup view controller
    var setup: AylaSetup
    
    /// Current presenting alert controller
    var alert: UIAlertController? {
        willSet(newAlert) {
            if let oldAlert = alert {
                // If there is an alert presenting to user. dimiss it first.
                oldAlert.dismissViewControllerAnimated(false, completion: nil)
            }
        }
    }
    
    /// Current running connect task
    var currentTask: AylaConnectTask?
    
    /// Scan results which are presented in table view
    var scanResults :AylaWifiScanResults?
    
    /// Last used token.
    var token: String?
    
    required init?(coder aDecoder: NSCoder)
    {
        // Init setup
        setup = AylaSetup(SDKRoot: AylaNetworks.shared())
        
        super.init(coder: aDecoder)
        
        // Monitor connectivity
        self.monitorDeviceConnectivity()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        // Init setup
        setup = AylaSetup(SDKRoot: AylaNetworks.shared())
    
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
        
        // Monitor connectivity
        self.monitorDeviceConnectivity()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign self as delegate and data source of tableview.
        tableView.delegate = self
        tableView.dataSource = self
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem:.Refresh, target: self, action: #selector(refresh))
        self.navigationItem.rightBarButtonItem = refreshButton
        
        attemptToConnect()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updatePrompt(prompt: String?) {
        self.navigationController?.navigationBar.topItem?.prompt = prompt
    }
    
    /**
     Monitor device connectivity by adding KVO to property `connected` of setup device.
     */
    func monitorDeviceConnectivity() {
        // Add observer to setup device connection status.
        setup.addObserver(self, forKeyPath: "setupDevice.connected", options: .New, context: nil)
    }
    
    /**
     Use this method to connect to device again.
     */
    func refresh() {
        
        // Clean scan results
        scanResults = nil
        tableView.reloadData()
        
        attemptToConnect()
    }
    
    /**
     Must use this method to start setup for a device.
     */
    func attemptToConnect() {

        updatePrompt("loading...")
        
        currentTask = setup.connectToNewDevice({ (setupDevice) -> Void in
            self.addDescription("Find device: \(setupDevice.dsn)")
            // Start fetching ap list.
            self.fetchApList()
            }) { (error) -> Void in
            self.updatePrompt("No device found")
            self.addDescription("Unable to find device: \(error.description)")
        }
    }

    /**
     Use this method to fetch ap list from setup.
     */
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
    
    /**
     Use this method to connect device to the input SSID
     
     - parameter ssid:     The ssid which device would connect to.
     - parameter password: Password of the ssid.
     */
    func connectToSSID(ssid: String, password: String?) {
    
        token = generateRandomToken(7)
        
        self.updatePrompt("Connecting device to '\(ssid)'...")
        let tokenString = String(format:"Using Setup Token %@", self.token!)
        self.addDescription(tokenString)
        self.setup.connectDeviceToServiceWithSSID(ssid, password: password, setupToken: token!, latitude: 0.0, longitude: 0.0, success: { () -> Void in
            
            // Succeeded, go confirming.
            self.addDescription("Connected to \(ssid)")
            
            // Call to confirm connection.
            self.confirmConnectionToService()
            
            }) { (error) -> Void in
            self.updatePrompt("Failed")
            self.displayError(error)
        }
    }
    
    /**
     Use this method to confirm device connnection status with cloud service.
     */
    func confirmConnectionToService() {
        self.updatePrompt("Confirming device status ...")
        self.setup.confirmDeviceConnectedWithTimeout(60.0, dsn:(self.setup.setupDevice?.dsn)!, setupToken:token!, success: { () -> Void in
            self.updatePrompt("- Succeeded -")
            self.addDescription("Confirmed device connection to service.\n- Succeeded -");

            let alertString = String(format:"Setup for device %@ completed successfully, using the setup token %@.\n\n You may wish to store this token if the device uses AP Mode registration.", (self.setup.setupDevice?.dsn)!, self.token!)
            let alert = UIAlertController(title: "Setup Successful", message: alertString, preferredStyle: .Alert)
            let copyAction = UIAlertAction(title: "Copy Token to Clipboard", style: .Default, handler: { (action) -> Void in
                UIPasteboard.generalPasteboard().string = self.token!
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: { (action) -> Void in
            })
            alert.addAction(copyAction)
            alert.addAction(cancelAction)
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.setupToken = self.token
            appDelegate.setupDSN = self.setup.setupDevice?.dsn

            self.presentViewController(alert, animated: true, completion: nil)

            // Clean scan results
            self.scanResults = nil
            self.tableView.reloadData()
            
            
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
    
    /**
     Display an error with UIAlertController
     
     - parameter error: The error which is going to be displayed.
     */
    func displayError(error:NSError) {
    
        if let currentAlert = alert {
            currentAlert.dismissViewControllerAnimated(false, completion: nil)
        }
        
        let alertController = UIAlertController(title: "Error", message: "\(error.userInfo[AylaRequestErrorResponseJsonKey]!)", preferredStyle: .Alert)
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
        self.setup.removeObserver(self, forKeyPath: "setupDevice.connected")
    }
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        if let result = scanResults?.results[indexPath.row] {
            
            // Compose an alert controller to let user input password.
            // TODO: If password is not required, the password text field should be removed from alert.
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
                // Edit actions, empty for now.
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
    
    func generateRandomToken(length:Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var token = ""
        
        for _ in (0..<length) {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let newCharacter = allowedChars[allowedChars.startIndex.advancedBy(randomNum)]
            token += String(newCharacter)
        }
        return token
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
