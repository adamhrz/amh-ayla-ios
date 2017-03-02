//
//  GrillRightViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 12/29/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class GrillRightViewController: UIViewController, AylaDeviceListener {
    static let sensor1Segue = "Sensor1Segue"
    static let sensor2Segue = "Sensor2Segue"
    /// Id of a segue which is linked to device page.
    static let segueIdToDevice = "toDeviceDetailsPage"
    
    var sensor1VC: GrillRightSensorViewController!
    var sensor2VC: GrillRightSensorViewController!
    
    var device: GrillRightDevice! {
        didSet {
            self.device.addListener(self)
        }
    }
    var sharesModel: DeviceSharesModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let info = UIBarButtonItem(barButtonSystemItem:.Action, target: self, action: #selector(GrillRightViewController.showDeviceDetails))
        self.navigationItem.rightBarButtonItem = info
    }
    
    func showDeviceDetails(){
        performSegueWithIdentifier(GrillRightViewController.segueIdToDevice, sender: self.device)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case GrillRightViewController.sensor1Segue:
                let sensorController = segue.destinationViewController as! GrillRightSensorViewController
                sensorController.sensor = device.channel1
                sensorController.device = device
                sensor1VC = sensorController
            case GrillRightViewController.sensor2Segue:
                let sensorController = segue.destinationViewController as! GrillRightSensorViewController
                sensorController.sensor = device.channel2
                sensorController.device = device
                sensor2VC = sensorController
            case GrillRightViewController.segueIdToDevice: // To device page
                if let device = sender as? AylaDevice {
                    let detailsController = segue.destinationViewController as! DeviceViewController
                    detailsController.device = device
                    detailsController.sharesModel = self.sharesModel
                }
            default:
                break;
            }
        }
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        if let change = change as? AylaPropertyChange {
            switch change.property.name {
            case (let n) where n.containsString("00:"):
                sensor1VC.refreshUI(change)
            case (let n) where n.containsString("01:"):
                sensor2VC.refreshUI(change)
            default:
                break;
            }
        } else if let change = change as? AylaDeviceChange, device = change.device as? GrillRightDevice {
            sensor1VC.controlsShouldEnableForDevice(device)
            sensor2VC.controlsShouldEnableForDevice(device)
        }
    }
    
    func device(device: AylaDevice, didFail error: NSError) {
        print(error)
    }

}
