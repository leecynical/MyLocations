//
//  FirstViewController.swift
//  MyLocations
//
//  Created by 李金钊 on 15/5/19.
//  Copyright (c) 2015年 lijinzhao. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    var location: CLLocation? //store current user location
    
    var updatingLocation = false
    var lastLocationError: NSError?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
    var timer: NSTimer?
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation"{
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
        }
    }
    
    func stopLocationManager(){
        if updatingLocation{
            if let timer = timer {
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func startLocationManager(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "didTimeOut", userInfo: nil, repeats: false)
        }
    }
    
    func didTimeOut(){
        println("*** Time out")
        if location == nil{
            stopLocationManager()
            
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            
            updateLabels()
            configureGetButton()
        }
    }
    
    func configureGetButton(){
        if updatingLocation{
            getButton.setTitle("Stop", forState: .Normal)
        }else{
            getButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    func updateLabels(){
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            addressLabel.text = ""
            tagButton.hidden = false
            if let placemark = placemark{
                addressLabel.text = stringFromPlacemark(placemark)
            }else if performingReverseGeocoding{
                addressLabel.text = "Searching for Address..."
            }else if lastLocationError != nil{
                addressLabel.text = "Error Finding Address"
            }else{
                addressLabel.text = "No Address Found"
            }
        }else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            tagButton.hidden = true
            addressLabel.text = ""
            
            var statusMessage: String
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue{ //disable only for this app
                    statusMessage = "Location Services Disabled"
                }else{
                    statusMessage = "Error Getting Location" // CLError.Network
                }
                
            }else if !CLLocationManager.locationServicesEnabled(){ // completely disable on device
                statusMessage = "Location Services Disabled"
            }else if updatingLocation {
                statusMessage = "Searching..."
            }else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
    }
    
    @IBAction func getLocation() {
        //check the current authorization status, if NotDetermined requestwheninuse
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .NotDetermined{
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        if updatingLocation{
            stopLocationManager()
        }else{
            location = nil
            lastLocationError = nil
            placemark = nil
            performingReverseGeocoding = false
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    func showLocationServicesDeniedAlert(){
        let alert = UIAlertController(
            title: "Location Services Disabled",
            message: "Please enable location services for this app in Settings",
            preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func stringFromPlacemark(placemark: CLPlacemark) -> String{
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare)\n"
             + "\(placemark.locality) \(placemark.administrativeArea) "
             + "\(placemark.postalCode)"
    }

}
// MARK: -CLLocationManagerDelegate
extension CurrentLocationController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("didFailWithError \(error)")
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        lastLocationError = error
        
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let newLocation = locations.last as! CLLocation
        println("didUpdateLocations \(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocation.horizontalAccuracy < 0{
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location{
            distance = newLocation.distanceFromLocation(location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            updateLabels()
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                println("*** We're done!")
                stopLocationManager()
                configureGetButton()
                
                if distance > 0 {
                    performingReverseGeocoding = false
                }
            }
            
            if !performingReverseGeocoding{
                println("*** Going to geocode")
                
                performingReverseGeocoding = true
                
                geocoder.reverseGeocodeLocation(location, completionHandler: {
                    placemarks, error in
                    
                    println("*** Found placemarks: \(placemarks), error: \(error)")
                    
                    self.lastLocationError = error
                    if error == nil && !placemarks.isEmpty{
                        self.placemark = placemarks.last as? CLPlacemark
                    }else {
                        self.placemark = nil
                    }
                    
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
        }else if distance < 1.0 {
            let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
            if timeInterval > 10 {
                println("*** Force done")
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
    }
}
