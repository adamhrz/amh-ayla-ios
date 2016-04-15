//
//  UIColor+AuraColors.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 4/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    class func auraLeafGreenColor() -> UIColor{
        return UIColor(hue: 90/360.0,
                       saturation: 87/100.0,
                       brightness: 64/100.0,
                       alpha: 1.0)
    }
    class func auraRedColor() -> UIColor{
        return UIColor(hue: 8/360.0,
                       saturation: 85/100.0,
                       brightness: 68/100.0,
                       alpha: 1.0)
    }
    class func auraDarkLeafGreenColor() -> UIColor{
        return UIColor(hue: 50/360.0,
                       saturation: 86/100.0,
                       brightness: 14/100.0,
                       alpha: 1.0)
    }
    class func auraLightSandColor() -> UIColor{
        return UIColor(hue: 53/360.0,
                       saturation: 8/100.0,
                       brightness: 89/100.0,
                       alpha: 1.0)
    }
}