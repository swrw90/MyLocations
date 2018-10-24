//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Seth Watson on 10/5/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
    
    var timer: Timer?
    var managedObjectContext: NSManagedObjectContext!
    
    var logoVisible = false
    
    lazy var logoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(getLocation), for: .touchUpInside)
        button.center.x = self.view.bounds.midX
        button.center.y = 220
        return button
        }()
    
    // Stores current location as nil until Core Location returns valid CCLocation object
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    // Geocoder handles geocoding, placemark contains address results
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    
    //    MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    //    MARK: - Outlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    
    //    MARK: - Actions
    
    //  Sets CurrentLocationViewController as locationManagers delegate, sets location accuracy to ten meters, sends location updates to delegate
    @IBAction func getLocation() {
        
        //request When In Use authorization for getting location
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            
            return
        }
        
        if logoVisible {
            hideLogoView()
        }
        
        //stopLocationManager on stop click
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
    }
    
    
    //    MARK: - LocationManagerDelegate
    let locationManager = CLLocationManager()
    
    // handle updating the location and it's labels
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        // If location result takes longer than 5 seconds result will be most recently found location
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        // If horizontal accuracy is lower than 0 ignore location results
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        // Calculate distance between new reading and previous
        var distance = CLLocationDistance( Double.greatestFiniteMagnitude)
        
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        
        // If location nil this is first update, compares accuracy and sets location
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy{
            location = newLocation
            lastLocationError = nil
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("*** We're done")
                stopLocationManager()
            }
            
            // Forces reverseGeocoding to obtain final most recent location
            if distance > 0 {
                performingReverseGeocoding = false
            }
            updateLabels()
            
            //checks if apps busy geocoding
            if !performingReverseGeocoding {
                print("*** Going to geocode")
                
                performingReverseGeocoding = true
                
                // Tell CLGeocoder object to reverse geocode the location, execute code block as soon as the geocoding is completed
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
                    placemarks, error in
                    self.lastGeocodingError = error
                    
                    // Check placemarks array contains at least one placemark, set last placemark in array to placemark property
                    // Else the coordinates arent significantly differnt in last 10sec stop fetching and use current result
                    if error == nil, let p = placemarks, !p.isEmpty {
                        self.placemark = p.last!
                    } else {
                        self.placemark = nil
                    }
                    
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            } else if distance < 1 {
                let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
                if timeInterval > 10 {
                    print("*** Force Done")
                }
                stopLocationManager()
                updateLabels()
            }
        }
    }
    
    
    //handle error if unable to get location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
        
        //if locationManager is unable to find location
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        
        stopLocationManager()
        updateLabels()
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            //            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            if let timer = timer{
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    // Always called after 1min with or without valid location unless stopLocationManager cancels timer first
    @objc func didTimeOut() {
        print("*** Time Out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            updateLabels()
        }
    }
    
    func updateLabels() {
        
        // Unwrap location, convert to String, set to label text
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            latitudeTextLabel.isHidden = false
            longitudeTextLabel.isHidden = false
            
            tagButton.isHidden = false
            messageLabel.text = ""
            
            //show address to user
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for address"
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            }
            
            
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            latitudeTextLabel.isHidden = true
            longitudeTextLabel.isHidden = true
            
            //Determine current state of app and set messageLabel at top of screen
            let statusMessage: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    //if user disabled services for app
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled(){
                //if services completely disabled for device
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                //waiting for location info to return
                statusMessage = "Searching..."
            } else {
                //initial state
                statusMessage = ""
                showLogoView()
            }
            messageLabel.text = statusMessage
        }
        configureGetButton()
    }
    
    func showLogoView() {
        if !logoVisible {
            logoVisible = true
            containerView.isHidden = true
            view.addSubview(logoButton)
        }
    }
    
    func hideLogoView() {
        if !logoVisible { return }
        
        logoVisible = false
        containerView.isHidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
//      containerView is placed outside the screen (somewhere on the right) and moved to the center
        let centerX = view.bounds.midX
        

        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.isRemovedOnCompletion = false
        panelMover.fillMode = CAMediaTimingFillMode.forwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(cgPoint: containerView.center)
        panelMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        panelMover.delegate = self
        containerView.layer.add(panelMover, forKey: "panelMover")
        
//      The logo image view slides out of the screen
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.isRemovedOnCompletion = false
        
        logoMover.fillMode = CAMediaTimingFillMode.forwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(cgPoint: logoButton.center)
        logoMover.toValue = NSValue(cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoMover, forKey: "logoMover")
        
//        The logo image also rotates around its center, giving the impression that it’s rolling away.
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.isRemovedOnCompletion = false
        logoRotator.fillMode = CAMediaTimingFillMode.forwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * Double.pi
        logoRotator.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoRotator, forKey: "logoRotator")
    }
    
    //if app is updating button text changes to stop
    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
        }
    }
    
    // Format CLPlacemark into string
    func string(from placemark: CLPlacemark) -> String {
        var line1 = ""
        line1.add(text: placemark.subThoroughfare)
        line1.add(text: placemark.thoroughfare)
        
        var line2 = ""
        line2.add(text: placemark.locality)
        line2.add(text: placemark.administrativeArea)
        line2.add(text: placemark.postalCode)
        
        line1.add(text: line2, separatedBy: "\n")
        return line1
    }
    
    
    //    MARK: - Handle location permission errors
    
    // Notify user to enable location service for app
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(
            title: "Location Services Disabled",
            message: "Please enable location services for this app in Settings under Privacy.",
            preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation
    
    // Sets values of props for segue destination table view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    
    // MARK:- Animation Delegate Methods
    
//    removes the logo button
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }
}
