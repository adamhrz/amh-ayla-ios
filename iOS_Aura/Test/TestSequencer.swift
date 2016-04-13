//
//  TestSequencer.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 4/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation

typealias CompleteBlock = TestSequencer -> Void

/*
 A TestSequencer manages a list of TestCases, it counts error when going through all error cases and call completeBlock when all test cases have been finished.
 */
class TestSequencer : NSObject {
    
    // MARK - Settings
    
    /// If test should continue when one of test case was failed.
    var continueAfterFailure :Bool = true

    // MARK - Attributes
    
    private(set) var nextTestIndex :Int = 0
    private(set) var testSuite :Array<TestCase> = []
    
    private(set) var errCount :Int = 0
    
    private(set) var STARTED :Bool = false
    private(set) var FINISHED :Bool = false
    private(set) var STOPPED :Bool = false

    var completeBlock :CompleteBlock?
    
    func addTest(description :String, testBlock :TestBlock) -> TestSequencer {
        let test = TestCase(description: description, testBlock: testBlock)
        test.sequencer = self
        testSuite.append(test)
        return self
    }
    
    func addTestCase(testCase :TestCase) -> TestSequencer {
        testCase.sequencer = self
        testSuite.append(testCase)
        return self
    }
    
    func start() {
        STARTED = true
        if testSuite.count > 0 {
            // Reset index
            nextTestIndex = 0
            
            let testCase = testSuite[0]
            testCase.start()
        }
        else  {
            FINISHED = true
        }
    }
    
    func stop() {
        STOPPED = true
        FINISHED = true
    }

    internal func finish() {
        FINISHED = true
        if let completeBlock = self.completeBlock {
            completeBlock(self)
        }
    }
    
    func finishedTestCase(testCase :TestCase) {
        if testCase.FAILED {
            errCount += 1
        }
        
        if !STOPPED {
            if testCase.FAILED && !continueAfterFailure {
                finish()
            }
            else {
                nextTestIndex += 1
                if nextTestIndex < testSuite.count {
                    let testCase = testSuite[nextTestIndex]
                    testCase.start()
                }
                else {
                    finish()
                }
            }
        }
        else {
            finish()
        }
    }
    
}