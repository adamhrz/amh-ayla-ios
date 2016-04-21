//
//  PropertyListViewModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

protocol PropertyListViewModelDelegate: class {
    func propertyListViewModel(viewModel:PropertyListViewModel, didSelectProperty property:AylaProperty, assignedPropertyModel propertyModel:PropertyModel)
    func propertyListViewModel(viewModel:PropertyListViewModel, displayPropertyDetails property:AylaProperty, assignedPropertyModel propertyModel:PropertyModel)
}

class PropertyListViewModel: NSObject, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, AylaDeviceListener {
    
    /// Default property cell id
    static let PropertyCellId: String = "PropertyCellId"
    /// Expanded property cell id
    static let ExpandedPropertyCellId: String = "ExpandedPropertyCellId"
    
    /// Device
    let device: AylaDevice
    
    /// Delegate of property list view model
    weak var delegate: PropertyListViewModelDelegate?
    
    /// Table view of properties
    var tableView: UITableView
    
    /// Table view search bar
    let searchController:UISearchController?
    
    /// Properties which are being represented in table view.
    var properties : [ AylaProperty ]
    
    required init(device: AylaDevice, tableView: UITableView) {
        
        self.device = device
        self.properties = []
        
        self.tableView = tableView
        self.searchController = UISearchController(searchResultsController: nil)
        
        super.init()
        
        // Add self as device listener
        device.addListener(self)
        
        // Set search controller
        self.searchController?.searchResultsUpdater = self
        
        // Add search bar to table view
        self.searchController?.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchController?.searchBar
        
        // Set a content offset to hide search bar.
        let barHeight = self.searchController?.searchBar.frame.size.height ?? 0
        self.tableView.contentOffset = CGPointMake(0, barHeight)
        
        tableView.delegate = self
        tableView.dataSource = self
        self.updatePropertyListFromDevice(userSearchText: nil)
    }
    
     /**
     Use this method to reload property list from device.
     
     - parameter searchText: User input search text, when set as nil, this api will only call tableview.reloadData()
     */
    func updatePropertyListFromDevice(userSearchText searchText:String?) {
        
        if let knownProperties = self.device.properties {
            // Only refresh properties list when there is a user search or property list is still empty.
            if searchText != nil || self.properties.count == 0 || self.properties.count != knownProperties.count {
                self.properties = knownProperties.values.map({ (property) -> AylaProperty in
                    return property as! AylaProperty
                }).filter({ (property) -> Bool in
                    return searchText ?? "" != "" ? property.name.lowercaseString.containsString(searchText!.lowercaseString) : true
                }).sort({ (prop1, prop2) -> Bool in
                    // Do a sort to the property list based on property names.
                    return prop1.name < prop2.name
                })
            }
        }
        else {
            // No properties list found in device
            self.properties = []
        }
        
        tableView.reloadData()
    }
    
    /**
     A tap gesture recognizer uses this method to show an alert for modifying property values/creating datapoints.
     
     - parameter sender: UITapGestureRecognizer
     - parameter property: the AylaProperty to create datapoints for
     */
    func showValueAlertForProperty(sender: UITapGestureRecognizer, property: AylaProperty){
        self.delegate?.propertyListViewModel(self, didSelectProperty: property, assignedPropertyModel: PropertyModel(property: property, presentingViewController: nil))
    }
    
    /**
     A tap gesture recognizer uses this method to segue to a Property Details page.
     
     - parameter sender: UITapGestureRecognizer
     - parameter property: the AylaProperty to create datapoints for
     */
    func showDetailsForProperty(sender: UITapGestureRecognizer, property: AylaProperty){
        self.delegate?.propertyListViewModel(self, displayPropertyDetails: property, assignedPropertyModel: PropertyModel(property: property, presentingViewController: nil))
    }
    
    // MARK: Table View Data Source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.properties.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellId = PropertyListViewModel.ExpandedPropertyCellId
        let item = self.properties[indexPath.row] as AylaProperty
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId) as? PropertyTVCell
        
        if (cell != nil) {
            cell?.configure(item)
        }
        else {
            assert(false, "\(cellId) - reusable cell can't be dequeued'")
        }
        cell?.parentPropertyListViewModel = self
        return cell!
    }
    
    // MARK: Table View Delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    // MARK - search controller

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let search = searchController.searchBar.text {
           self.updatePropertyListFromDevice(userSearchText: search)
        }
    }
    
    // MARK - device listener
    
    func device(device: AylaDevice, didFail error: NSError) {
        // We do nothing to handle device errors here.
    }
    
    func device(device: AylaDevice, didObserveChange change: AylaChange) {
        // Not a smart way to update.
        if(change.isKindOfClass(AylaPropertyChange)) {
            log("Obverse changes: \(change)", isWarning: false)
            self.updatePropertyListFromDevice(userSearchText: nil)
        }
    }
}
