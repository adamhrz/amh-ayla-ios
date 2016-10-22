//
//  NetworkProfilerModel.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 10/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import QuartzCore
import AFNetworking

class NetworkProfilerModel: TestModel, AylaLanTaskProfilerListener, AylaCloudTaskProfilerListener {
    var device :AylaDevice!
    var networkDuration : CFTimeInterval = 0
    
    init(testPanelVC: TestPanelViewController, device: AylaDevice?) {
        super.init(testPanelVC: testPanelVC)
        
        self.device = device
        AylaProfiler.sharedInstance().addListener(self)
    }
    
    var totalTimes = ( lan:  Array<CFTimeInterval>(), cloud : Array<CFTimeInterval>())
    var networkTimes = ( lan:  Array<CFTimeInterval>(), cloud : Array<CFTimeInterval>())
    
    func didStartLANTask(task: AylaConnectTask!) {
        
    }
    
    func didFailLANTask(task: AylaConnectTask!, duration: CFTimeInterval) {
        networkDuration = duration
    }
    
    func didSucceedLANTask(task: AylaConnectTask!, duration: CFTimeInterval) {
        networkDuration = duration
    }
    
    func didStartTask(task: NSURLSessionDataTask!) {
        
    }
    
    func didFailTask(task: NSURLSessionDataTask!, duration: CFTimeInterval) {
        networkDuration = duration
    }
    
    func didSucceedTask(task: NSURLSessionDataTask!, duration: CFTimeInterval) {
        networkDuration = duration
    }
    override func testPanelIsReady() {
        testPanelVC?.title = "Network Profiler"
        testPanelVC?.tf1.hidden = false
        testPanelVC?.tf1Label.hidden = false
        testPanelVC?.tf1Label.text = "Iters"
        testPanelVC?.tf1.keyboardType = .NumberPad
        
        testPanelVC?.tf2.hidden = false
        testPanelVC?.tf2Label.hidden = false
        testPanelVC?.tf2Label.text = "LAN Mode"
        testPanelVC?.tf2.keyboardType = .NumberPad
        testPanelVC?.tf2.enabled = false
        testPanelVC?.tf2.text = (device != nil && device!.isLanModeActive() ? "Enabled" : "Unavailable")
        
        testPanelVC?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(clearConsole))
        
    }
    
    func clearConsole() {
        testPanelVC?.consoleView.clear()
        totalTimes = ( lan:  Array<CFTimeInterval>(), cloud : Array<CFTimeInterval>())
        networkTimes = ( lan:  Array<CFTimeInterval>(), cloud : Array<CFTimeInterval>())
    }
    
    func testTurnBlueLEDOnViaCloud(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        let blueLEDProperty = device?.getProperty("Blue_LED")
        let turnOffDatapoint = AylaDatapointParams ()
        turnOffDatapoint.value = 0
        
        addLog(.Info, log: "Turning blue LED on via Cloud")
        let startTime = CACurrentMediaTime()
        blueLEDProperty?.createDatapointCloud(turnOffDatapoint, success: { (createdDatapoint) in
            
            let endTime = CACurrentMediaTime();
            let totalTime = endTime-startTime
            self.totalTimes.cloud.append(totalTime)
            self.networkTimes.cloud.append(self.networkDuration)
            self.addLog(.Info, log: self.timeResultsDescription("Cloud", totalTime: totalTime, networkTime: self.networkDuration))
            
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    func timeResultsDescription(operationType:String, totalTime:CFTimeInterval, networkTime:CFTimeInterval) -> String {
        return "\(operationType) Operation Total: \(String(format: "%.0f",totalTime*1000))ms, Network Total: \(String(format: "%.0f",networkTime*1000))ms, \(String(format: "%.2f%%",networkTime/totalTime*100))"
    }
    
    func testTurnBlueLEDOffViaCloud(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        let blueLEDProperty = device?.getProperty("Blue_LED")
        let turnOffDatapoint = AylaDatapointParams ()
        turnOffDatapoint.value = 0
        
        addLog(.Info, log: "Turning blue LED off via Cloud")
        let startTime = CACurrentMediaTime()
        blueLEDProperty?.createDatapointCloud(turnOffDatapoint, success: { (createdDatapoint) in
            
            let endTime = CACurrentMediaTime();
            let totalTime = endTime-startTime
            self.totalTimes.cloud.append(totalTime)
            self.networkTimes.cloud.append(self.networkDuration)
            self.addLog(.Info, log: self.timeResultsDescription("Cloud", totalTime: totalTime, networkTime: self.networkDuration))
            
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    func testTurnBlueLEDOnViaLAN(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        let blueLEDProperty = device?.getProperty("Blue_LED")
        let turnOffDatapoint = AylaDatapointParams ()
        turnOffDatapoint.value = 0
        
        addLog(.Info, log: "Turning blue LED on via LAN")
        let startTime = CACurrentMediaTime()
        blueLEDProperty?.createDatapointLAN(turnOffDatapoint, success: { (createdDatapoint) in
            
            let endTime = CACurrentMediaTime();
            let totalTime = endTime-startTime
            self.totalTimes.lan.append(totalTime)
            self.networkTimes.lan.append(self.networkDuration)
            self.addLog(.Info, log: self.timeResultsDescription("LAN", totalTime: totalTime, networkTime: self.networkDuration))
            
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    func testTurnBlueLEDOffViaLAN(tc: TestCase)  {
        addLog(.Info, log: "Start \(#function)")
        let blueLEDProperty = device?.getProperty("Blue_LED")
        let turnOffDatapoint = AylaDatapointParams ()
        turnOffDatapoint.value = 0
        
        addLog(.Info, log: "Turning blue LED off via LAN")
        let startTime = CACurrentMediaTime()
        blueLEDProperty?.createDatapointLAN(turnOffDatapoint, success: { (createdDatapoint) in
            
            let endTime = CACurrentMediaTime();
            let totalTime = endTime-startTime
            self.totalTimes.lan.append(totalTime)
            self.networkTimes.lan.append(self.networkDuration)
            self.addLog(.Info, log: self.timeResultsDescription("LAN", totalTime: totalTime, networkTime: self.networkDuration))
            
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
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
    
    override func setupTestSequencer() {
        let sequencer = TestSequencer()
            .addTest(NSStringFromSelector(#selector(testTurnBlueLEDOnViaCloud)), testBlock: { [weak self] (testCase) in self?.testTurnBlueLEDOffViaCloud(testCase) })
            .addTest(NSStringFromSelector(#selector(testTurnBlueLEDOffViaCloud)), testBlock: { [weak self] (testCase) in self?.testTurnBlueLEDOffViaCloud(testCase) })
        if device.isLanModeActive() {
            sequencer
                .addTest(NSStringFromSelector(#selector(testTurnBlueLEDOnViaLAN)), testBlock: { [weak self] (testCase) in self?.testTurnBlueLEDOnViaLAN(testCase) })
                .addTest(NSStringFromSelector(#selector(testTurnBlueLEDOffViaLAN)), testBlock: { [weak self] (testCase) in self?.testTurnBlueLEDOffViaLAN(testCase) })
        }
        
        testSequencer = sequencer
    }
    override func finishedOnTestSequencer(testSequencer: TestSequencer) {
        super.finishedOnTestSequencer(testSequencer)
        addLog(.Info, log: "Results: \(timeResultsDescription("Cloud", totalTime: totalTimes.cloud.reduce(0,combine: { $0 + $1 }), networkTime: networkTimes.cloud.reduce(0,combine: { $0 + $1 })))")
        addLog(.Info, log: "Average Results: \(timeResultsDescription("Cloud", totalTime: totalTimes.cloud.reduce(0,combine: { $0 + $1 })/Double(self.totalTimes.cloud.count), networkTime: networkTimes.cloud.reduce(0,combine: { $0 + $1 })/Double(self.networkTimes.cloud.count)))")
        
        
        addLog(.Info, log: "Results: \(timeResultsDescription("LAN", totalTime: totalTimes.lan.reduce(0,combine: { $0 + $1 }), networkTime: networkTimes.lan.reduce(0,combine: { $0 + $1 })))")
        addLog(.Info, log: "Average Results: \(timeResultsDescription("LAN", totalTime: totalTimes.lan.reduce(0,combine: { $0 + $1 })/Double(self.totalTimes.lan.count), networkTime: networkTimes.lan.reduce(0,combine: { $0 + $1 })/Double(self.networkTimes.lan.count)))")
    }
}
