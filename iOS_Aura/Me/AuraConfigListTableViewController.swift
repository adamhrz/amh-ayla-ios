//
//  AuraConfigListTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 9/9/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

class AuraConfigListTableViewController: UITableViewController {
    
    let cellIdentifier = "AuraConfigCellIdentifier"
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
    }

    lazy var configURLList : [NSURL]! = {
        [unowned self] in
        let fileManager = NSFileManager.defaultManager()
        
        let paths = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = paths[0]
        
        do {
            let allContents = try fileManager.contentsOfDirectoryAtURL(documentsDirectory, includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants, .SkipsPackageDescendants])
            var filesOnly = [NSURL]()
            for item in allContents {
                var isDirectory : ObjCBool = ObjCBool(false)
                
                if fileManager.fileExistsAtPath(item.path!, isDirectory: &isDirectory) && isDirectory {
                    continue
                }
                filesOnly.append(item)
            }
            return filesOnly
        } catch _ {
            UIAlertController.alert("Error", message: "Could not read Documents directory", buttonTitle: "OK", fromController: self)
            return nil
        }
    }()
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return configURLList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)

        let url = configURLList[indexPath.row]
        
        cell.textLabel?.text = url.lastPathComponent

        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(configURLList[indexPath.row])
            } catch {
                print("Failed to delete file")
            }
            
            configURLList.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }

}
