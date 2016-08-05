//
//  TestPanelViewController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 4/8/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit

protocol TestPanelVCDelegate {
    func testPanelVC(viewController: TestPanelViewController, didTapOnStartButton startButton: UIButton) -> Bool
    
    func testPanelVC(viewController: TestPanelViewController, didTapOnStopButton stopButton: UIButton) -> Bool
    
    func testPanelVC(viewController: TestPanelViewController, didTapOnButton1 button1: UIButton) -> Bool
    
    func testPanelVC(viewController: TestPanelViewController, didTapOnButton2 button2: UIButton) -> Bool
    
    func testPanelVC(viewController: TestPanelViewController, didTapOnButton3 button3: UIButton) -> Bool
}

/**
 Default view controller for integration/function tests. Developers can go to Test.storyboard to find the corresponding UI
 
 @note TestPanelViewController is designed to be shared among test models. Any significant changes to existing UI components are highly discouraged.
        If necessary, developers could always subclass this test panel view controller (or create a new view controller) to satisfy test requirements.
        Read comments in TestModel for more details.
 */
class TestPanelViewController: UIViewController {
    
    @IBOutlet weak var rightBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var consoleView: AuraConsoleTextView!
    
    @IBOutlet weak var tf1Label: UILabel!
    @IBOutlet weak var tf1: UITextField!
    
    @IBOutlet weak var tf2Label: UILabel!
    @IBOutlet weak var tf2: UITextField!
    
    @IBOutlet weak var tf3Label: UILabel!
    @IBOutlet weak var tf3: UITextField!
    
    @IBOutlet weak var btn1: UIButton!
    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var btn3: UIButton!
    
    @IBOutlet weak var startButton: AuraButton!
    @IBOutlet weak var statusTF: UITextField!
    
    @IBOutlet weak var errCountLabel: UILabel!
    @IBOutlet weak var iterCountLabel: UILabel!
    
    var testModel :TestModel?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        initDefaultUIState()
        
        let leftBarButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(cancel))
        self.navigationItem.leftBarButtonItem = leftBarButton

        startButton.addTarget(self, action: #selector(startButtonTapped), forControlEvents: .TouchUpInside)
        
        assert(testModel != nil, "Test model can't be nil");
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        testModel?.testPanelIsReady()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    func cancel() {
        testModel?.testPanelIsDismissed()
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func resetStartButton() {
        startButton.setTitle("Start", forState: .Normal)
    }

    private func initDefaultUIState() {
        consoleView.backgroundColor = UIColor.whiteColor()

        tf1.hidden = true
        tf1Label.hidden = true
        btn1.hidden = true

        tf2.hidden = true
        tf2Label.hidden = true
        btn2.hidden = true

        tf3.hidden = true
        tf3Label.hidden = true
        btn3.hidden = true
    }
    
    @objc private func startButtonTapped() {
        if let model = testModel {
            if(startButton.currentTitle?.lowercaseString == "start") {
                let start = model.testPanelVC(self, didTapOnStartButton:startButton)
                if start {
                    statusTF.text = TestModelTestState.Working.rawValue
                    startButton.setTitle("Stop", forState: .Normal)
                }
            }
            else {
                let stop = model.testPanelVC(self, didTapOnStopButton :startButton)
                if stop {
                    statusTF.text = TestModelTestState.Empty.rawValue
                    startButton.setTitle("Start", forState: .Normal)
                }
            }
        } else {
            log("No test model found for this test panel.", isWarning: false)
        }
    }
    
    /**
     Use this method to append a string on text view.
    */
    func outputLogText(text :String) {
        consoleView.addLogLine(text)
    }
    
    func dismissKeyboard() {
        tf1.resignFirstResponder()
        tf2.resignFirstResponder()
        tf3.resignFirstResponder()
    }
    
    /**
     Use this method to append an attributed string on text view.
     */
    func outputAttributedLogText(attributedText :NSAttributedString) {
        consoleView.addAttributedLogline(attributedText)
    }
    
}
