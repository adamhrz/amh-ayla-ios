//
//  TimeZonePickerViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

/// TimeZonePickerViewControllerDelegate

protocol TimeZonePickerViewControllerDelegate: class {
    func timeZonePickerDidCancel(picker: TimeZonePickerViewController)
    func timeZonePicker(picker: TimeZonePickerViewController, didSelectTimeZoneID timeZoneID:String)
}

// MARK: -

class TimeZonePickerViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {

    /// Delegate
    weak var delegate:TimeZonePickerViewControllerDelegate?

    /// Identifier (name) of the currently selected time zone
    var timeZoneID:String? {
        get {
            return self.internalTimeZoneID
        }
        set {
            internalTimeZoneID = newValue
            self.selectTimeZone(self.internalTimeZoneID)
        }
    }
    
    internal var internalTimeZoneID:String? = nil
    
    @IBOutlet weak var tableView: UITableView!
    
    let cellReuseIdentifier = "TimeZonePickerCell"
    let timeZones = NSTimeZone.knownTimeZoneNames()
    
    enum TimeZonePickerViewControllerSection: Int {
        case TimeZonePickerViewControllerSectionTimeZones = 0, TimeZonePickerViewControllerSectionCount
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tintColor = UIColor.auraTintColor()
        self.tableView.allowsMultipleSelection = false;
        self.tableView.registerClass(TimeZonePickerTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.selectTimeZone(self.timeZoneID)
    }
    
    // MARK: - Actions

    @IBAction func cancel(sender: AnyObject) {
        self.delegate?.timeZonePickerDidCancel(self)
    }

    @IBAction func save(sender: AnyObject) {
        if (self.timeZoneID != nil) {
            self.delegate?.timeZonePicker(self, didSelectTimeZoneID: self.timeZoneID!)
        } else {
            let alert = UIAlertController(title: "Please select a time zone", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.Default, handler:nil)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Utilities
    
    func selectTimeZone(timeZone: String?) {
        if (self.tableView == nil) {
            return;
        }
        
        // Deselect the current selection, if there is one
        if let currentSelectionIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(currentSelectionIndexPath, animated: true)
        }
        
        // Select the specificed timeZone, if provided and it exists
        if timeZone != nil {
            if let index = self.timeZones.indexOf(timeZone!) {
                let indexPath = NSIndexPath.init(forRow: index, inSection: 0)
                self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
            }
        }
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TimeZonePickerViewControllerSection.TimeZonePickerViewControllerSectionCount.rawValue
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows:Int = 0
        
        if let timeZonePickerSection = TimeZonePickerViewControllerSection(rawValue: section) {
            switch timeZonePickerSection {
                case .TimeZonePickerViewControllerSectionTimeZones:
                    numRows = self.timeZones.count
                default:
                    assert(true, "Unexpected section!")
            }
        }
        
        return numRows
    }
       
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel!.text = self.timeZones[indexPath.row]
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        var highlight = true
        
        // Don't highlight the selected cell
        if (indexPath == tableView.indexPathForSelectedRow) {
            highlight = false;
        }

        return highlight
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        var pathToSelect:NSIndexPath? = nil
        
        // Don't allow additional selections of the currently selected cell
        if (indexPath != tableView.indexPathForSelectedRow) {
            pathToSelect = indexPath;
        }
        
        return pathToSelect
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let timeZonePickerSection = TimeZonePickerViewControllerSection(rawValue: indexPath.section) {
            switch timeZonePickerSection {
                case .TimeZonePickerViewControllerSectionTimeZones:
                    self.internalTimeZoneID = self.timeZones[indexPath.row]
                break
                default:
                    assert(true, "Unexpected section!")
            }
        }
    }
    
}

// MARK: -

class TimeZonePickerTableViewCell : UITableViewCell {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        // Update the background color to profide a visual affordance on touch down, but not have a highlight after touch up
        self.contentView.backgroundColor = highlighted ? UIColor.auraTintColor() : nil;
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        self.accessoryType = selected ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        self.textLabel?.textColor = selected ? UIColor.auraTintColor() : UIColor.blackColor()
    }
    
    func commonInit() {
        self.selectionStyle = UITableViewCellSelectionStyle.None
        self.textLabel?.backgroundColor = UIColor.clearColor()
    }
}
