//
//  AuraButton.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

public enum AuraButtonType : Int {
    case System // standard system button
    case Standard // standard button
}

class AuraButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.backgroundColor = UIColor.aylaHippieGreenColor().CGColor
        self.layer.cornerRadius = 5.0
        
        self.setTitleColor(UIColor.aylaPearlBushColor(), forState: UIControlState.Normal)
        self.setTitleColor(UIColor.aylaSisalColor(), forState: .Disabled)
    }
}

class AuraProgressButton: UIButton {
    var activityIndicator:UIActivityIndicatorView?
    var activityIndicatorColor:UIColor = UIColor.aylaSisalColor()
    
    override var enabled: Bool {
        didSet {
            self.alpha = enabled ? 1.0 : 0.6
        }
    }
    
    override func setTitle(title: String?, forState state: UIControlState) {
        if title != self.titleForState(state) {
            self.stopActivityIndicator()
        }
        super.setTitle(title, forState: state)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.backgroundColor = UIColor.aylaHippieGreenColor().CGColor
        self.layer.cornerRadius = 5.0
        
        self.setTitleColor(UIColor.aylaPearlBushColor(), forState: UIControlState.Normal)
        self.setTitleColor(UIColor.aylaSisalColor(), forState: .Disabled)
    }
    
    func startActivityIndicator(){
        let indicatorHeight = CGRectGetHeight(self.frame) - 8
    
        let cgX = CGRectGetWidth(self.frame) / 2 - indicatorHeight / 2
        let cgY = CGRectGetHeight(self.frame) / 2 - indicatorHeight / 2
        let cgWidth = indicatorHeight
        let cgHeight = indicatorHeight
        let activityIndicatorFrame:CGRect = self.convertRect(CGRectMake(cgX, cgY, cgWidth, cgHeight), toView: self.superview)
        if self.activityIndicator == nil {
            let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView.init(frame: activityIndicatorFrame)
            self.activityIndicator = activityIndicator;
        }
    
        self.activityIndicator?.userInteractionEnabled = false;
        self.activityIndicator?.color = self.activityIndicatorColor
        self.activityIndicator?.frame = activityIndicatorFrame;
        self.superview?.addSubview(self.activityIndicator!)
        self.activityIndicator?.startAnimating()
        self.enabled = false
    }
    
    func stopActivityIndicator() {
        if let indicator = self.activityIndicator {
            indicator.removeFromSuperview()
        }
        self.enabled = true;
    }
    
}

class AuraTextButton : UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setTitleColor(UIColor.aylaBahamaBlueColor(), forState: UIControlState.Normal)
        titleLabel?.font = UIFont.systemFontOfSize(12.0)
    }
}
