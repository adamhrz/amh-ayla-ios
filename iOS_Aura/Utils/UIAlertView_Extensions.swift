//
//  UIAlertView_Extensions.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
extension UIAlertController {
    class func alert(_ title: String?, message: String?, buttonTitle: String?, fromController controller: UIViewController, okHandler: @escaping (UIAlertAction)->Void = { _ in }) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction (title: buttonTitle, style: UIAlertActionStyle.default, handler:okHandler)
        alert.addAction(okAction)
        controller.present(alert, animated: true, completion: nil)
    }
}
