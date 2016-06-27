//
//  ContactNotificationButton.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

class ContactNotificationButton: UIButton {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if  let originalImage = self.currentImage {
            self.setImage(colorizeImage(originalImage, color:UIColor.aylaBombayColor()), forState: .Normal)
            self.setImage(colorizeImage(originalImage, color:UIColor.auraTintColor()), forState: .Selected)
        }
    }

    private func colorizeImage (image: UIImage, color: UIColor) -> UIImage {
        var newImage = image.imageWithRenderingMode(.AlwaysTemplate)
        
        UIGraphicsBeginImageContextWithOptions(newImage.size, false, newImage.scale)
        
        color.set()
        
        newImage.drawInRect(CGRect(x: 0.0, y: 0.0, width: newImage.size.width, height: newImage.size.height))
        
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
