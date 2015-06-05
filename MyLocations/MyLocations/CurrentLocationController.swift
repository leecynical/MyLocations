//
//  FirstViewController.swift
//  MyLocations
//
//  Created by 李金钊 on 15/5/19.
//  Copyright (c) 2015年 lijinzhao. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import QuartzCore
import AudioToolbox


class CurrentLocationController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    let locationManager = CLLocationManager()
    
    var location: CLLocation? //store current user location
    
    var updatingLocation = false
    var lastLocationError: NSError?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
    var timer: NSTimer?
    
    var managedObjectContext: NSManagedObjectContext!
    
    var logoVisible = false
    
    lazy var logoButton: UIButton = {
        
        let button = UIButton.buttonWithType(.Custom) as! UIButton
        button.setBackgroundImage(UIImage(named: "Logo"), forState: .Normal)
        button.sizeToFit()
        button.addTarget(self, action: "getLocation", forControlEvents: .TouchUpInside)
        button.center.x = CGRectGetMidX(self.view.bounds)
        button.center.y = 220
        return button
    }()
    
    var soundID: SystemSoundID = 0
    
    //MARK: -Sound Effect
    
    func loadSoundEffect(name: String){
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: nil){
            let fileURL = NSURL.fileURLWithPath(path, isDirectory: false)
            if fileURL == nil {
                println("NSURL is nil for path: \(path)")
                return
            }
            let error = AudioServicesCreateSystemSoundID(fileURL, &soundID)
            if Int(error) != kAudioServicesNoError{
                println("Error code \(error) loading sound at path: \(path)")
                return
            }
        }
    }
    
    func uploadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }
    
    func playSoundEffect(){
        AudioServicesPlaySystemSound(soundID)
    }
    
    //MARK: -Logo View
    
    func showLogoView(){
        if !logoVisible{
            logoVisible = true
            containerView.hidden = true
            view.addSubview(logoButton)
        }
    }
    
    func hideLogoView() {
        if !logoVisible{
            return
        }
        logoVisible = false
        containerView.hidden = false
        
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        let centerX = CGRectGetMidX(view.bounds)
        
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.removedOnCompletion = false
        panelMover.fillMode = kCAFillModeForwards // remain visible when completion
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(CGPoint: containerView.center)
        panelMover.toValue = NSValue(CGPoint: CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        panelMover.delegate = self
        containerView.layer.addAnimation(panelMover, forKey: "panelMover")
        
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.removedOnCompletion = false
        logoMover.fillMode = kCAFillModeForwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(CGPoint:logoButton.center)
        logoMover.toValue = NSValue(CGPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoMover, forKey: "logoMover")
        
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.removedOnCompletion = false
        logoRotator.fillMode = kCAFillModeForwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * M_PI
        logoRotator.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoRotator, forKey: "logoRotator")
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation"{
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
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
        
        let spinnerTag = 1000
        
        if updatingLocation{
            getButton.setTitle("Stop", forState: .Normal)
            
            if view.viewWithTag(spinnerTag) == nil {
                let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
                
                spinner.center = messageLabel.center
                spinner.center.y += spinner.bounds.size.height / 2 + 15
                spinner.startAnimating()
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        }else{
            getButton.setTitle("Get My Location", forState: .Normal)
            
            if let spinner = view.viewWithTag(spinnerTag) {
                spinner.removeFromSuperview()
            }
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
            
            latitudeTextLabel.hidden = false
            longitudeTextLabel.hidden = false
            
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
                statusMessage = ""
                showLogoView()
            }
            messageLabel.text = statusMessage
            latitudeTextLabel.hidden = true
            longitudeTextLabel.hidden = true
        }
    }
    
    @IBAction func getLocation() {
        //check the current authorization status, if NotDetermined requestwheninuse
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .NotDetermined{
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if logoVisible{
            hideLogoView()
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
        loadSoundEffect("Sound.caf")
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
                        if self.placemark == nil{
                            println("FIRST TIME")
                            self.playSoundEffect()
                        }
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
