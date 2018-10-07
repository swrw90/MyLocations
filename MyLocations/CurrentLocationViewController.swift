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
    
    //stores current location as nil until Core Location returns valid CCLocation object
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
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
        
        startLocationManager()
        updateLabels()
    }
    
    
    //    MARK: - LocationManagerDelegate
    let locationManager = CLLocationManager()
    
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
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    
    private func locationManager(_ manager: CLLocationManagerDelegate, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        //if location result takes longer than 5 seconds result will be most recently found location
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        //if horizontal accuracy is lower than 0 ignor location results
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        //if location nil this is first update, compares accuracy and sets location
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy{
            location = newLocation
            lastLocationError = nil
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("*** We're done")
                stopLocationManager()
            }
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
                statusMessage = "Locatiion Services Disabled"
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
