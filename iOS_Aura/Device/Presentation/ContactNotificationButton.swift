//
//  ContactNotificationButton.swift
//  iOS_Aura
//
//  Created by Brad Hochberg on 6/23/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

class ContactNotificationButton: UIButton {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // self.imageView?.image? = (self.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate))!
        
//        self.adjustsImageWhenHighlighted = false
        updateForSelectedState(self.selected)
    }

    override var selected: Bool {
        didSet {
            self.updateForSelectedState(selected)
        }
    }
    
    private func updateForSelectedState (selected: Bool) {
//        self.imageView?.tintColor = selected ? UIColor.aylaBahamaBlueColor() : UIColor.blackColor()
//        self.tintColor = selected ? UIColor.aylaBahamaBlueColor() : UIColor.blackColor()
    }
    
}
