//
//  AuraButton.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

public enum AuraButtonType : Int {
    case system // standard system button
    case standard // standard button
}

class AuraButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.backgroundColor = UIColor.aylaHippieGreenColor().cgColor
        self.layer.cornerRadius = 5.0
        
        self.setTitleColor(UIColor.aylaPearlBushColor(), for: UIControlState())
        self.setTitleColor(UIColor.aylaSisalColor(), for: .disabled)
    }
}

class AuraProgressButton: UIButton {
    var activityIndicator:UIActivityIndicatorView?
    var activityIndicatorColor:UIColor = UIColor.aylaSisalColor()
    
    override var isEnabled: Bool {
        didSet {
            self.alpha = isEnabled ? 1.0 : 0.6
        }
    }
    
    override func setTitle(_ title: String?, for state: UIControlState) {
        if title != self.title(for: state) {
            self.stopActivityIndicator()
        }
        super.setTitle(title, for: state)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.backgroundColor = UIColor.aylaHippieGreenColor().cgColor
        self.layer.cornerRadius = 5.0
        
        self.setTitleColor(UIColor.aylaPearlBushColor(), for: UIControlState())
        self.setTitleColor(UIColor.aylaSisalColor(), for: .disabled)
    }
    
    func startActivityIndicator(){
        let indicatorHeight = self.frame.height - 8
    
        let cgX = self.frame.width / 2 - indicatorHeight / 2
        let cgY = self.frame.height / 2 - indicatorHeight / 2
        let cgWidth = indicatorHeight
        let cgHeight = indicatorHeight
        let activityIndicatorFrame:CGRect = self.convert(CGRect(x: cgX, y: cgY, width: cgWidth, height: cgHeight), to: self.superview)
        if self.activityIndicator == nil {
            let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView.init(frame: activityIndicatorFrame)
            self.activityIndicator = activityIndicator;
        }
    
        self.activityIndicator?.isUserInteractionEnabled = false;
        self.activityIndicator?.color = self.activityIndicatorColor
        self.activityIndicator?.frame = activityIndicatorFrame;
        self.superview?.addSubview(self.activityIndicator!)
        self.activityIndicator?.startAnimating()
        self.isEnabled = false
    }
    
    func stopActivityIndicator() {
        if let indicator = self.activityIndicator {
            indicator.removeFromSuperview()
        }
        self.isEnabled = true;
    }
    
}

class AuraTextButton : UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setTitleColor(UIColor.aylaBahamaBlueColor(), for: UIControlState())
        titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    }
}
