//
//  PropertyViewController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 3/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

class PropertyViewController: UIViewController {

    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var baseTypeLabel: UILabel!
    
    var propertyModel: PropertyModel?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        refresh()
    }
    
    /**
     Use this method to refresh UI
     */
    func refresh() {
        if let property = propertyModel?.property {
            displayNameLabel.text = property.displayName
            valueLabel.text = "\(String.stringFromStringNumberOrNil(property.value))"
            nameLabel.text = property.name
            baseTypeLabel.text = property.baseType
        }
    }
    
}
