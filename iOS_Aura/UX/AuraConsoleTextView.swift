//
//  AuraConsoleTextView.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit

class AuraConsoleTextView : UITextView {
    
    enum ConsoleLoggingLevel {
        case Pass, Fail, Warning, Error, Info, Debug
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textColor = UIColor.darkTextColor()
        
        // Default background is light gray to contrast to default white vc background.
        self.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    private func tagFromLoggingLevel(level: ConsoleLoggingLevel) -> String {
        var tag :String
        switch level {
        case .Pass:
            tag = "P"
            break
        case .Fail:
            tag = "F"
            break
        case .Error:
            tag = "E"
            break
        case .Warning:
            tag = "W"
            break
        case .Info:
            tag = "I"
            break
        case .Debug:
            tag = "D"
            break
        }
        
        return tag
    }
    
    private func attributedStringFromLoggingLevel(level: ConsoleLoggingLevel, logText: String) -> NSAttributedString? {
        
        var htmlString :String = "\(tagFromLoggingLevel(level)), \(logText)"
        let fontSettings = "face=\"-apple-system\",\"HelveticaNeue\""
        switch level {
        case .Pass:
            htmlString = "<font \(fontSettings) color=\"LimeGreen\">\(htmlString)</font>"
            break
        case .Fail:
            htmlString = "<font \(fontSettings) color=\"Red\">\(htmlString)</font>"
            break
        case .Error:
            htmlString = "<font \(fontSettings) color=\"DarkBlue\">\(htmlString)</font>"
            break
        case .Warning:
            htmlString = "<font \(fontSettings) color=\"Blue\">\(htmlString)</font>"
            break
        case .Info:
            htmlString = "<font \(fontSettings)>\(htmlString)</font>"
            break
        case .Debug:
            htmlString = "<font \(fontSettings)>\(htmlString)</font>"
            break
        }
        
        let data = htmlString.dataUsingEncoding(NSUTF8StringEncoding)!
        let attributedOptions = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType]
        var string :NSAttributedString?
        do {
            string = try NSAttributedString(data: data, options: attributedOptions, documentAttributes: nil)
        } catch _ {
            print("Cannot create attributed String")
        }
        
        return string
    }
    
    /**
     Call this method to add a tagged log message to the console.
     Scrolls to bottom when done.
     - parameter level: Logging level of this message.
     - parameter log:   Log text.
     */
    func addLogLine(level: ConsoleLoggingLevel, log: String) {
        if let attributedLogText = attributedStringFromLoggingLevel(level, logText: log) {
            self.addAttributedLogline(attributedLogText)
        }
        else  {
            self.addLogLine("\(tagFromLoggingLevel(level)), \(log)")
        }
    }
    
    /**
     Use this method to add a new line to the console. Scrolls to bottom when done.
     */
    func addLogLine(untaggedLog: String) {
        self.addAttributedLogline(NSAttributedString(string: untaggedLog))
    }
    
    /**
     Use this method to append an attributed string on text view.
     */
    func addAttributedLogline(attributedText :NSAttributedString) {
        let wholeText =  self.attributedText.mutableCopy() as! NSMutableAttributedString
        wholeText.appendAttributedString(NSAttributedString(string: "\n"))
        wholeText.appendAttributedString(attributedText)
        self.attributedText = wholeText
        // This scrolls the view to the bottom when the text extends beyond the edges
        let count = self.text.characters.count
        let bottom = NSMakeRange(count, 0)
        self.scrollRangeToVisible(bottom)
        
    }
    
}

