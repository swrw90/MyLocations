//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Seth Watson on 10/5/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    var timer: Timer?
    
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
    
    
    //    MARK: - Outlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    
    //    MARK: - Actions
    
    //  Sets CurrentLocationViewController as locationManagers delegate, sets location accuracy to ten meters, sends location updates to delegate
    @IBAction func getLocation() {
        
        //request When In Use authorization for getting location
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            
            return
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
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
        configureGetButton()
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
        
        // If placemark has house name
        if let s = placemark.subThoroughfare {
            line1 += s + " "
        }
        
        // If placemark has street name
        if let s = placemark.thoroughfare {
            line1 += s
        }
        
        var line2 = ""
        
        // If placemark has city
        if let s = placemark.locality {
            line2 += s + " "
        }
        
        // If placemark has state or province
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        
        // If placemark has ziopcode
        if let s = placemark.postalCode {
            line2 += s
        }
        
        return line1 + "\n" + line2
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
    
}
