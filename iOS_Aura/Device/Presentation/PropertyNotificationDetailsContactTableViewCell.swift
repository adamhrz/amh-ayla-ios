//
//  PropertyNotificationDetailsContactTableViewCell.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK
import UIKit

class PropertyNotificationDetailsContactTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var emailButton: UIButton!
    @IBOutlet private weak var pushButton: UIButton!
    @IBOutlet private weak var smsButton: UIButton!
    
    weak var delegate:PropertyNotificationDetailsContactTableViewCellDelegate?
    
    var contact: AylaContact? = nil {
        didSet {
            self.configureForContact(contact)
        }
    }
    
    static let nib = UINib(nibName: "PropertyNotificationDetailsContactTableViewCell", bundle: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - Actions

    @IBAction private func email(button: UIButton) {
        button.selected = !button.selected;
        delegate?.didToggleEmail(self)
    }

    @IBAction private func push(button: UIButton) {
        button.selected = !button.selected;
        delegate?.didTogglePush(self)
    }

    @IBAction private func sms(button: UIButton) {
        button.selected = !button.selected;
        delegate?.didToggleSMS(self)
    }

    // MARK: - Utilities
    
    func configureForContact(contact: AylaContact?) {
        nameLabel.text = contact?.displayName
        
        var enabledApps:[AylaServiceAppType] = []
        
        if contact != nil {
            enabledApps = delegate?.enabledAppsForContact(contact!) ?? []
        }
        
        emailButton.hidden = (contact?.email ?? "").isEmpty
        smsButton.hidden = (contact?.phoneNumber ?? "").isEmpty
        
        // TODO: Unhide for owner
        pushButton.hidden = true
        
        emailButton.selected = enabledApps.contains(AylaServiceAppType.Email)
        pushButton.selected = enabledApps.contains(AylaServiceAppType.Push)
        smsButton.selected = enabledApps.contains(AylaServiceAppType.SMS)
    }
}

// MARK: -

protocol PropertyNotificationDetailsContactTableViewCellDelegate: class {
    
    // Client should return an array of the enabled apps for the specified contact.
    // The array can contain zero or more of the following constants: AylaServiceAppTypeEmail, AylaServiceAppTypePush, AylaServiceAppTypeSMS
    func enabledAppsForContact(contact: AylaContact) -> [AylaServiceAppType]
    
    // Client should enable or disable the email app for the associated contact
    func didToggleEmail(cell: PropertyNotificationDetailsContactTableViewCell)

    // Client should enable or disable the push notification app for the associated contact
    func didTogglePush(cell: PropertyNotificationDetailsContactTableViewCell)
    
    // Client should enable or disable the SMS app for the associated contact
    func didToggleSMS(cell: PropertyNotificationDetailsContactTableViewCell)
}
