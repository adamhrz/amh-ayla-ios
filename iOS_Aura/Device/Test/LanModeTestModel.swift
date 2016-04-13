//
//  LanModeTestModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 4/8/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK


extension AylaDevice {

    func lanTest_isSupportedDevice() -> Bool {
        if oemModel == "ledevb" {
            return true
        }
        return false
    }

    func lanTest_getProperty(name: String) -> AylaProperty? {
        if let properties = self.properties as? [String: AylaProperty]{
            return properties[name]
        }
        return nil
    }
    
    func lanTest_getBooleanProperty() -> AylaProperty? {
        if oemModel == "ledevb" {
            // Use green led
            return lanTest_getProperty("Green_LED")
        }
        
        var property: AylaProperty?
        if let properties = self.properties {
            let filtered = properties.filter({ (key, property) -> Bool in
                if property.baseType == "string" && property.direction == "input" {
                    return true
                }
                return false
            })
            
            if filtered.count > 0 {
                property = filtered[0].1 as? AylaProperty
            }
        }
        return property
    }

    func lanTest_getStringProperty() -> AylaProperty? {
        if oemModel == "ledevb" {
            // Use green led
            return lanTest_getProperty("cmd")
        }
        var property: AylaProperty?
        if let properties = self.properties {
            let filtered = properties.filter({ (key, property) -> Bool in
                if property.baseType == "boolean" && property.direction == "input" {
                    return true
                }
                return false
            })
            
            if filtered.count > 0 {
                property = filtered[0].1 as? AylaProperty
            }
        }
        return property
    }
    
    func lanTest_getAckEnableBooleanProperty() -> AylaProperty? {
        return nil
    }
    
    func lanTest_confirmPropertyFor(property: AylaProperty) -> AylaProperty? {
        if property.name == "cmd" {
            return lanTest_getProperty("log")
        }
        return property
    }
    
}

class LanModeTestModel: TestModel {
    
    var deviceManager: AylaDeviceManager?
    var device :AylaDevice?
    
    init(testPanelVC: TestPanelViewController, deviceManager:AylaDeviceManager?, device: AylaDevice?) {
        super.init(testPanelVC: testPanelVC)
        
        self.deviceManager = deviceManager
        self.device = device
    }
    
    override func testPanelIsReady() {
        testPanelVC?.title = "LAN Test"
        testPanelVC?.tf1Label.text = "Iters"
        testPanelVC?.tf1.keyboardType = .NumberPad
    }
    
    override func start() -> Bool {
        if (super.start()) {
            setupTestSequencer()
            
            var iters = 1
            if let text = self.testPanelVC?.tf1.text {
                if let input = Int(text) {
                    iters = input > 0 ? input : 1
                }
            }

            self.testPanelVC?.iterCountLabel.text = "1/\(iters)"
            testSequencer?.start(UInt(iters))
            return true
        }
        
        return false
    }
    
    override func stop() -> Bool {
        return super.stop()
    }
    
    override func setupTestSequencer() {
        let sequencer = TestSequencer()
            .addTest(NSStringFromSelector(#selector(testFetchPropertiesLAN)), testBlock: { [weak self] (testCase) in self?.testFetchProperties(testCase) })
            .addTest(NSStringFromSelector(#selector(testFetchProperties)), testBlock: { [weak self] (testCase) in self?.testFetchProperties(testCase) })
            .addTest(NSStringFromSelector(#selector(testCreateBooleanDatapointLAN)), testBlock: { [weak self] (testCase) in self?.testCreateBooleanDatapointLAN(testCase) })
            .addTest(NSStringFromSelector(#selector(testCreateStringDatapointLAN)), testBlock: { [weak self] (testCase) in self?.testCreateStringDatapointLAN(testCase) })
            .addTest(NSStringFromSelector(#selector(testDatapointAckWithBooleanPropertyLAN)), testBlock: { [weak self] (testCase) in self?.testDatapointAckWithBooleanPropertyLAN(testCase) })
            .addTest(NSStringFromSelector(#selector(testFetchPropertiesLAN)), testBlock: { [weak self] (testCase) in self?.testFetchPropertiesLAN(testCase) })
        
        testSequencer = sequencer
    }

    // NOTE: Lan Mode Test Model only supports devices with oemModel `ledevb`
    // You could still start test for other modules, but there is no gurantee Lan Mode Test could be fully passed
    
    // MARK Test in sequence

    func testFetchProperties(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        device?.fetchProperties(nil, success: { (properties) in
            self.passTestCase(tc)
            }, failure: { (error) in
            self.failTestCase(tc, error: error)
        })
    }
    
    func testFetchPropertiesLAN(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        device?.fetchPropertiesLAN(nil, success: { (properties) in
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    func testCreateBooleanDatapointLAN(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        let device = self.device
        let property: AylaProperty? = device?.lanTest_getBooleanProperty()
        
        if property == nil {
            addLog(.Warning, log: "Unable to find boolean property")
            passTestCase(tc)
            return
        }
        
        // Create a datapoint
        let dp = AylaDatapointParams()
        dp.value = NSNumber(int: 1 - property!.datapoint.value.intValue)
        addLog(.Info, log: "Using property \(property?.name), dp.value \(dp.value)")
        
        createAndConfirmDatapoint(tc, property: property!, datapoint: dp, confirmProperty: device?.lanTest_confirmPropertyFor(property!)) { (createdDatapoint) -> Bool in
            return createdDatapoint.value.boolValue == dp.value.boolValue
        }
    }
    
    func testCreateStringDatapointLAN(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        let device = self.device
        let property = device?.lanTest_getStringProperty()
        
        if property == nil {
            addLog(.Warning, log: "Unable to find string property")
            passTestCase(tc)
            return
        }
        
        // Create a datapoint
        let dp = AylaDatapointParams()
        dp.value = "TEST_STRING \(Int(arc4random_uniform(9999)))"
        addLog(.Info, log: "Using property \(property?.name), dp.value \(dp.value)")
        
        createAndConfirmDatapoint(tc, property: property!, datapoint: dp, confirmProperty: device?.lanTest_confirmPropertyFor(property!)) { (createdDatapoint) -> Bool in
            return createdDatapoint.value as! String == dp.value as! String
        }
    }

    func testDatapointAckWithBooleanPropertyLAN(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        let device = self.device
        let property = device?.lanTest_getAckEnableBooleanProperty()
        
        if property == nil {
            addLog(.Warning, log: "Unable to find ACK enable boolean property, skip.")
            passTestCase(tc)
            return
        }
        
        // Create a datapoint
        let dp = AylaDatapointParams()
        dp.value = NSNumber(int: 1 - property!.datapoint.value.intValue)
        addLog(.Info, log: "Using property \(property?.name), dp.value \(dp.value)")
        
        property?.createDatapointLAN(dp, success: { (datapoint) in
            if datapoint.ackStatus == 0 {
                self.addLog(.Error, log: "Ack status = 0")
                self.failTestCase(tc, error: nil)
            }
            else if datapoint.value.boolValue != dp.value.boolValue {
                self.addLog(.Error, log: "DP value mismatched.")
                self.failTestCase(tc, error: nil)
            }
            else {
                self.passTestCase(tc)
            }
            }, failure: { (error) in
            self.failTestCase(tc, error: error)
        })

    }

    func createAndConfirmDatapoint(tc:TestCase, property: AylaProperty, datapoint: AylaDatapointParams , confirmProperty: AylaProperty?, checkBlock: (AylaDatapoint) -> Bool)  {

        let device = self.device
        // Create a datapoint
        
        property.createDatapointLAN(datapoint, success: { (datapoint) in
            // Fetch from device to guarantee the created datapoint
            if confirmProperty != nil {
                // Delay 1s before fetching property to confirm
                dispatch_after(1, dispatch_get_main_queue(), {
                    self.addLog(.Info, log: "Fetching property \"\(confirmProperty!.name)\" to confirm datapoint.")
                    device?.fetchPropertiesLAN([ confirmProperty!.name ], success: { (properties) in
                            if let dp = properties.first?.datapoint {
                                if checkBlock(dp) {
                                    self.passTestCase(tc)
                                }
                                else {
                                    self.addLog(.Error, log: "DP value mismatched.")
                                    self.failTestCase(tc, error: nil)
                                }
                            }
                            else {
                                self.addLog(.Error, log: "DP is missing.")
                                self.failTestCase(tc, error: nil)
                            }
                        }, failure: { (error) in
                        self.failTestCase(tc, error: error)
                    })
                })
            } else {
                self.addLog(.Warning, log: "No confirm property given for property \(property.name)")
                self.failTestCase(tc, error: nil)
            }
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
}