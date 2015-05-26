//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by 李金钊 on 15/5/20.
//  Copyright (c) 2015年 lijinzhao. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class LocationDetailsViewController: UITableViewController {
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!

    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    
    var descriptionText = ""
    var categoryName = "No Category"
    
    private let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    var managedObjectContext: NSManagedObjectContext!
    var date = NSDate()
    
    //MARK: unwind segue
    
    @IBAction func categoryPickerViewController(segue: UIStoryboardSegue){
        let controller = segue.sourceViewController as! CategoryPickerViewController
        
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    @IBAction func done(sender: AnyObject) {
        let hudView = HudView.hudInView(navigationController!.view, animated: true)
        hudView.text = "Tagged"
        
        let location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedObjectContext) as! Location
        
        location.locationDescription = descriptionText
        location.longitude = coordinate.longitude
        location.latitude = coordinate.latitude
        location.date = date
        location.placemark = placemark
        location.category = categoryName
        
        var error: NSError?
        if !managedObjectContext.save(&error){
            fatalCoreDataError(error)
            return
        }
        
        afterDelay(0.6){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func cancel(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format:"%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark{
            addressLabel.text = stringFromPlacemark(placemark)
        }else{
            addressLabel.text = "No Address Found"
        }
        
        dateLabel.text = formateDate(date)
        
        let gestureRecongizer = UITapGestureRecognizer(target: self, action: "hideKeyboard:")
        gestureRecongizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecongizer)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        descriptionTextView.frame.size.width = view.frame.size.width - 30
    }
    
    func hideKeyboard(gestureRecongizer: UIGestureRecognizer){
        let point = gestureRecongizer.locationInView(tableView) // gesture took place in tableView
        let indexPath = tableView.indexPathForRowAtPoint(point)
        
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0{
            return
        }
        descriptionTextView.resignFirstResponder()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0{
            return 88
        }else if indexPath.section == 2 && indexPath.row == 2{
            addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            return addressLabel.frame.size.height + 20
        }else{
            return 44
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0{
            descriptionTextView.becomeFirstResponder()
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 0 || indexPath.section == 1{
            return indexPath
        }else {
            return nil
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickCategory"{
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String{
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare)\n"
            + "\(placemark.locality) \(placemark.administrativeArea) "
            + "\(placemark.postalCode)"
    }
    
    func formateDate(date: NSDate) -> String{
        return dateFormatter.stringFromDate(date)
    }
}

extension LocationDetailsViewController: UITextViewDelegate{
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        descriptionText = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        descriptionText = textView.text
    }
    
}



