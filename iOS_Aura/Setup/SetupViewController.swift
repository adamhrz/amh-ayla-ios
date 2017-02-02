//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import PDKeychainBindingsController
import iOS_AylaSDK

class SetupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AylaDeviceWifiStateChangeListener {

    /// Setup cell id
    private static let CellId: String = "SetupCellId"
    
    /// Description view to display status
    @IBOutlet private weak var consoleView: AuraConsoleTextView!
    
    /// Table view of scan results
    @IBOutlet private weak var tableView: UITableView!
    
    /// A reserved view for future use.
    @IBOutlet private weak var controlPanel: UIView!
    
    /// AylaSetup instance used by this setup view controller
    private var setup: AylaSetup
    
    /// Current presenting alert controller
    private var alert: UIAlertController? {
        willSet(newAlert) {
            if let oldAlert = alert {
                // If there is an alert presenting to user. dimiss it first.
                oldAlert.dismissViewControllerAnimated(false, completion: nil)
            }
        }
    }
    
    /// Wi-Fi 'state' as provided by the device being set up.
    private var moduleWiFiState: String! = "none" {
        willSet(newState){
            if newState != moduleWiFiState {
                let prompt = "Module Reported WiFi State: '\(newState)'"
                addDescription(prompt)
            }
        }
    }
    
    /// Current running connect task
    private var currentTask: AylaConnectTask?
    
    /// Scan results which are presented in table view
    private var scanResults :AylaWifiScanResults?
    
    /// Last used token.
    private var token: String?
    
    /// Default timeout for device cloud connection polling
    private let defaultCloudConfirmationTimeout = 60.0
    
    
    required init?(coder aDecoder: NSCoder){
        // Init setup
        setup = AylaSetup(SDKRoot: AylaNetworks.shared())
        
        super.init(coder: aDecoder)
        
        //register as WiFi State listener
        setup.addWiFiStateListener(self)
        
        // Monitor connectivity
        monitorDeviceConnectivity()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        // Init setup
        setup = AylaSetup(SDKRoot: AylaNetworks.shared())
    
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
        
        // Monitor connectivity
        monitorDeviceConnectivity()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign self as delegate and data source of tableview.
        tableView.delegate = self
        tableView.dataSource = self
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem:.Refresh, target: self, action: #selector(refresh))
        navigationItem.rightBarButtonItem = refreshButton
        
        attemptToConnect()
    }
    
    private func updatePrompt(prompt: String?) {
        navigationController?.navigationBar.topItem?.prompt = prompt
    }
    
    /**
     Monitor device connectivity by adding KVO to property `connected` of setup device.
     */
    private func monitorDeviceConnectivity() {
        // Add observer to setup device connection status.
        setup.addObserver(self, forKeyPath: "setupDevice.connected", options: .New, context: nil)
    }
    
    /**
     Use this method to connect to device again.
     */
    @objc private func refresh() {
        // Clean scan results
        scanResults = nil
        tableView.reloadData()
        
        attemptToConnect()
    }
    
    /**
     Writes the setupDevice's registrationType string to the consoleView
     */
    private func logRegistrationTypeForSetupDevice(setupDevice:AylaSetupDevice){
        let registrationType = AylaRegistration.registrationNameFromType(setupDevice.registrationType)
        addDescription("Device will use \(registrationType ?? "Unknown") Registration Type.")

    }
    
    /**
     Writes the setupDevice's details to the consoleView
     */
    private func logDetailsForSetupDevice(setupDevice:AylaSetupDevice){
        let indent = "    "
        self.addDescription("Device Details:")
        addDescription(indent + "DSN: \(setupDevice.dsn ?? "none")")
        addDescription(indent + "FW version: \(setupDevice.version ?? "none")")
        addDescription(indent + "FW build: \(setupDevice.build ?? "none")")
        addDescription(indent + "LAN IP: \(setupDevice.lanIp ?? "none")")
        addDescription(indent + "MAC: \(setupDevice.mac ?? "none")")
        addDescription(indent + "Model: \(setupDevice.model ?? "none")")

        if let features = setupDevice.features {
            addDescription(indent + "Features:")
            for feature in features {
                addDescription(indent + indent + "\(feature)")
            }
        }
    }
    
    /**
     Must use this method to start setup for a device.
     */
    private func attemptToConnect() {

        updatePrompt("Connecting...")
        addDescription("Looking for a device to set up.")
        setup.connectToNewDevice({ (setupDevice) -> Void in
            self.addDescription("Found Device")
            self.logDetailsForSetupDevice(setupDevice)
            
            // Start fetching AP list from module.
            self.fetchFreshAPListWithWiFiScan()
            
            }) { (error) -> Void in
                self.updatePrompt("")
                self.addDescription("Unable to find device: \(error.aylaServiceDescription)")
                let message = "Are you connected to the Wi-Fi access point of the device you wish to set up?\n\nIf not, please tap the button below to move to the Settings application.  Navigate to Wi-Fi settings section and select the AP/network name for your device.\n\nOnce the network is joined, you should be redirected here momentarily."
                let alert = UIAlertController(title: "No Device Found", message: message, preferredStyle: .Alert)
                let settingsAction = UIAlertAction(title: "Go To Settings App", style:.Default, handler: { (action) in
                    self.dismissViewControllerAnimated(false, completion: {
                        UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
                    })
                })
                let cancelAction = UIAlertAction(title: "Cancel", style:.Cancel, handler: { (action) in
                    self.updatePrompt("No Device Found")
                })
                alert.addAction(settingsAction)
                alert.addAction(cancelAction)
                self.presentViewController(alert, animated: true, completion: {})
        }
    }

    /**
     * Use this method to have the module scan for Wi-Fi access points, then fetch the resulting AP list from setup.
     */
    private func fetchFreshAPListWithWiFiScan() {
        addDescription("Device is scanning for Wi-Fi Access Points...")
        currentTask = setup.startDeviceScanForAccessPoints({
            self.addDescription("Scan Complete. Fetching results.")
            self.fetchCurrentAPList()
            }) { (error) in
                let message = "Wi-Fi Scan Failed"
                self.updatePrompt(message)
                self.displayError(error, message: message)
        }
    }
    
    /**
     * Use this method to have the setup device scan for Wi-Fi access points.
     */
    private func fetchCurrentAPList(){
        currentTask = setup.fetchDeviceAccessPoints({ (scanResults) -> Void in
            self.addDescription("Received AP list.")
            self.updatePrompt(self.setup.setupDevice?.dsn ?? "")
            self.scanResults = scanResults
            self.tableView.reloadData()
            
            }, failure: { (error) -> Void in
                self.updatePrompt("Error")
                let message = "An error occurred while trying to fetch the Wi-Fi scan results."
                self.displayError(error, message: message)
        })

    }
    
    /**
     Use this method to connect device to the input SSID
     
     - parameter ssid:     The ssid which device would connect to.
     - parameter password: Password of the ssid.
     */
    private func connectToSSID(ssid: String, password: String?) {
    
        token = String.generateRandomAlphanumericToken(7)
        
        updatePrompt("Connecting device to '\(ssid)'...")
        addDescription("Connecting device to the network '\(ssid)'...")

        let tokenString = String(format:"Using Setup Token %@.", token!)
        addDescription(tokenString)
        setup.connectDeviceToServiceWithSSID(ssid, password: password, setupToken: token!, latitude: 0.0, longitude: 0.0, success: { (wifiStatus) -> Void in
            
            // Succeeded, go confirming.
            self.addDescription("Device reports connection to SSID.")
            // Call to confirm connection.
            self.confirmConnectionToService()
            
            }) { (error) -> Void in
            var message = ""
            let errorCode = UInt16(error.aylaResponseErrorCode)

            switch errorCode {
            case AylaWifiConnectionError.ConnectionTimedOut.rawValue:
                message += "Connection Timed Out"
            case AylaWifiConnectionError.InvalidKey.rawValue:
                message += "Invalid Wi-Fi Key Entered"
            case AylaWifiConnectionError.NotAuthenticated.rawValue:
                message += "Failed to Authenticate"
            case AylaWifiConnectionError.IncorrectKey.rawValue:
                message += "Incorrect Wi-Fi Key Entered"
            case AylaWifiConnectionError.Disconnected.rawValue:
                message += "Disconnected from Device"
            default:
                message += "AylaWifiConnectionError Code \(errorCode)"
            }
            self.updatePrompt("Setup Failed")
            self.displayError(error, message: message)
        }
    }
    
    /**
     Use this method to confirm device connnection status with cloud service.
     */
    private func confirmConnectionToService() {
        func storeDeviceDetailsInKeychain(){
            // Store device info in keychain for use during a later registration attempt.
            PDKeychainBindings.sharedKeychainBindings().setString(self.token, forKey: AuraDeviceSetupTokenKeychainKey)
            PDKeychainBindings.sharedKeychainBindings().setString(self.setup.setupDevice?.dsn, forKey: AuraDeviceSetupDSNKeychainKey)
        }
        
        updatePrompt("Confirming device connection status ...")
        addDescription("Polling cloud service to confirm device connection.\n Timeout set to \(Int(defaultCloudConfirmationTimeout)) seconds. Please wait...")
        let deviceDSN = setup.setupDevice?.dsn
        
        setup.confirmDeviceConnectedWithTimeout(defaultCloudConfirmationTimeout, dsn:(deviceDSN)!, setupToken:token!, success: { (setupDevice) -> Void in
                self.logRegistrationTypeForSetupDevice(setupDevice)
                self.updatePrompt("- Succeeded -")
                self.addDescription("- Wi-Fi Setup Complete -")

                let alertString = String(format:"Setup for device %@ completed successfully, using the setup token %@.\n\n You may wish to store this token if the device uses AP Mode registration.", (self.setup.setupDevice?.dsn)!, self.token!)

                let alert = UIAlertController(title: "Setup Successful", message: alertString, preferredStyle: .Alert)
                let copyAction = UIAlertAction(title: "Copy Token to Clipboard", style: .Default, handler: { (action) -> Void in
                    UIPasteboard.generalPasteboard().string = self.token!
                    storeDeviceDetailsInKeychain()
                })
                let cancelAction = UIAlertAction(title: "No, Thanks", style: .Cancel, handler: { (action) -> Void in
                    storeDeviceDetailsInKeychain()
                })
                if let sessionManager = AylaNetworks.shared().getSessionManagerWithName(AuraSessionOneName) {
                    var deviceAlreadyRegistered = false
                    let devices = sessionManager.deviceManager.devices.values.map({ (device) -> AylaDevice in
                        return device as! AylaDevice
                    })
                    for device in devices {
                        if device.dsn == deviceDSN {
                            deviceAlreadyRegistered = true
                            self.addDescription("FYI, Device appears to be registered or shared to you already.");
                        }
                    }
                    
                    if deviceAlreadyRegistered == false {
                        let registerNowAction = UIAlertAction(title: "Register Device Now", style: .Default, handler: { (action) -> Void in
                            storeDeviceDetailsInKeychain()
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let regVC = storyboard.instantiateViewControllerWithIdentifier("registrationController")
                                self.navigationController?.pushViewController(regVC, animated: true)
                        })
                        alert.addAction(registerNowAction)
                    }
                }
                
                alert.addAction(copyAction)
                alert.addAction(cancelAction)

                self.presentViewController(alert, animated: true, completion: nil)

                // Clean scan results
                self.scanResults = nil
                self.tableView.reloadData()
            
            }) { (error) -> Void in
                let message = "Confirmation step has failed."
                self.displayError(error, message: message)
        }
    }
    
    /**
     Use this method to add a description to description text view.
     */
    private func addDescription(description: String) {
        consoleView.addLogLine(description)
        print("Log: " + description)
    }
    
    /**
     Display an error with UIAlertController
     
     - parameter error: The error which is going to be displayed.
     - parameter message: Message to be displayed along with error.
     */
    private func displayError(error:NSError, message: String?) {
        
        if let currentAlert = alert {
            currentAlert.dismissViewControllerAnimated(false, completion: nil)
        }
        let serviceDescription = error.aylaServiceDescription
        var errorText = ""
        if let message = message {
            errorText = message + "\n\nAylaError: '" + serviceDescription + "'"
        }
        
        let alertController = UIAlertController(title: "Error", message: errorText, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Got it", style: .Cancel, handler: nil))
        alert = alertController
        self.presentViewController(alertController, animated: true, completion: nil)
        addDescription("Error: \(message ?? "")\n    '\(serviceDescription)'")
    }
    
    @IBAction private func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true) { () -> Void in
            self.setup.exit()
        }
    }
    
    deinit {
        setup.removeObserver(self, forKeyPath: "setupDevice.connected")
        setup.removeWiFiStateListener(self)
    }
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        if let result = scanResults?.results[indexPath.row] {
            
            // Compose an alert controller to let user input password.
            // TODO: If password is not required, the password text field should be removed from alert.
            let alertController = UIAlertController(title: "Password Required", message: "Please input password for the network \"\(result.ssid)\".", preferredStyle: .Alert)
            
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
            
            presentViewController(alertController, animated: true, completion: nil)
            
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
        let results = scanResults?.results as [AylaWifiScanResult]!
            
        let result = results[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(SetupViewController.CellId)
            
        cell?.textLabel!.text = result.ssid + "\n    \(result.security),  Signal: \(result.signal) dBm"
        cell!.selectionStyle = UITableViewCellSelectionStyle.None
            
        return cell!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanResults?.results.count ?? 0
    }
    
    // MARK: - KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if object === setup.setupDevice as? AnyObject {
            if let device = object as? AylaSetupDevice {
                if !device.connected {
                    updatePrompt("Lost Connectivity To Device")
                }
            }
        }
    }
    
    func wifiStateDidChange(state: String) {
        moduleWiFiState = state
    }

}
