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
    }
}

class AuraTextButton : UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setTitleColor(UIColor.aylaBahamaBlueColor(), forState: UIControlState.Normal)
        titleLabel?.font = UIFont.systemFontOfSize(12.0)
    }
}