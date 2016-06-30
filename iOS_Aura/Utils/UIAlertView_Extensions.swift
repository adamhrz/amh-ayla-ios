//
//  UIAlertView_Extensions.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
extension UIAlertController {
    class func alert(title: String?, message: String?, buttonTitle: String?, fromController controller: UIViewController, okHandler: (UIAlertAction)->Void = { _ in }) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction (title: buttonTitle, style: UIAlertActionStyle.Default, handler:okHandler)
        alert.addAction(okAction)
        controller.presentViewController(alert, animated: true, completion: nil)
    }
}