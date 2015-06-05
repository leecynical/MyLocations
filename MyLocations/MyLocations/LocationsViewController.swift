//
//  LocationsViewController.swift
//  MyLocations
//
//  Created by 李金钊 on 15/5/26.
//  Copyright (c) 2015年 lijinzhao. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController {

    var managedObjectContext: NSManagedObjectContext!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
       
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entity
        
        let sortDescriptor1 = NSSortDescriptor(key: "category", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]
        fetchRequest.fetchBatchSize = 20
        
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "category", cacheName: "Locations")
        
        fetchResultsController.delegate = self
        return fetchResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.4)
        tableView.indicatorStyle = .White
        
        performFetch()
        navigationItem.rightBarButtonItem = editButtonItem()
    }
    
    deinit{
        fetchedResultsController.delegate = nil
    }
    
    func performFetch(){
        var error: NSError?
        if !fetchedResultsController.performFetch(&error){
            fatalCoreDataError(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.name!.uppercaseString
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationCell", forIndexPath: indexPath) as! LocationCell

        let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
        
        cell.configureForLocation(location)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
            location.removePhotoFile()
            managedObjectContext.deleteObject(location)
            
            var error: NSError?
            if !managedObjectContext.save(&error){
                fatalCoreDataError(error)
            }
        }
    }
    // labelRect separatorRect fixed?? tableView.sectionHeaderHeight
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let labelRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 14, width: 300, height: 14) // sectionHeaderHeight = 22 ??
        let label = UILabel(frame: labelRect)
        label.font = UIFont.boldSystemFontOfSize(11)
        
        label.text = tableView.dataSource!.tableView!(tableView, titleForHeaderInSection: section) //self.tableView(tableView, titleForHeaderInSection: section)
        
        label.textColor = UIColor(white: 1.0, alpha: 0.4)
        label.backgroundColor = UIColor.clearColor()
        
        let separatorRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 0.5, width: tableView.bounds.size.width - 15, height: 0.5)
        let separator = UIView(frame: separatorRect)
        separator.backgroundColor = tableView.separatorColor
        
        let viewRect = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.sectionHeaderHeight)
        let view = UIView(frame: viewRect)
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.85)
        view.addSubview(label)
        view.addSubview(separator)
        return view
    }
    
    // MARK:

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell){
                let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
                controller.locationToEdit = location
            }
        }
    }
}

extension LocationsViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        println("*** controllerWillChangeContent")
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            println("*** NSFetchedResultsControllerChangeInsert (object)")
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            println("*** NSFetchedResultsControllerChangeDelete (object)")
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            println("*** NSFetchedResultsControllerChangeUpdate (object)")
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LocationCell{
                let location = controller.objectAtIndexPath(indexPath!) as! Location
                cell.configureForLocation(location)
            } // fix crash by not updating object
        case .Move:
            println("*** NSFetchedResultsControllerChangeMove (object)")
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            println("*** NSFetchedResultsChangeInsert (section)")
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            println("*** NSFetchedResultsChangeDelete (section)")
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Update:
            println("*** NSFetchedResultsChangeUpdate (section)")
        case .Move:
            println("*** NSFetchedResultsChangeMove (section)")
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        println("*** ControllerDidChangeContent")
        tableView.endUpdates()
    }
}




































