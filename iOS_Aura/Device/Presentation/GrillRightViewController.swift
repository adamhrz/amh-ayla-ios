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
    
    var sensor1VC: GrillRightSensorViewController!
    var sensor2VC: GrillRightSensorViewController!
    
    var device: GrillRightDevice! {
        didSet {
            self.device.addListener(self)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
                sensor1VC = sensorController
            case GrillRightViewController.sensor2Segue:
                let sensorController = segue.destinationViewController as! GrillRightSensorViewController
                sensorController.sensor = device.channel2
                sensor2VC = sensorController
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
        }
    }
    
    func device(device: AylaDevice, didFail error: NSError) {
        print(error)
    }

}
