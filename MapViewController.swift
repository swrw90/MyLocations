//
//  MapViewController.swift
//  MyLocations
//
//  Created by Seth Watson on 10/19/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//

import UIKit
import CoreData
import MapKit


class MapViewController: UIViewController {
    var locations = [Location]()
    
    // didSet block tells the NotificationCenter to add an observer for the NSManagedObjectContextObjectsDidChange notification
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: OperationQueue.main) { notification in
                if self.isViewLoaded {
                    self.updateLocations()
                    
                }
            }
        }
    }
    
    
    //    MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetches the Location objects and shows them on the map when the view loads
        updateLocations()
        
        if !locations.isEmpty{
            showLocations()
        }
    }
    
    
    //MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    
    // MARK: - Actions
    @IBAction func showUser() {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        mapView.setRegion(mapView.regionThatFits(region),animated: true)
    }
    
    @IBAction func showLocations() {
        // Call region(for:) to calculate a reasonable region that fits all the Location objects and then sets that region on the map view
        let theRegion = region(for: locations)
        mapView.setRegion(theRegion, animated: true)
    }
    
    @objc func showLocationDetails(_ sender: UIButton) {
        performSegue(withIdentifier: "EditLocation", sender: sender)
    }
    
    
    // MARK:- Navigation
    
    // Get Location object to edit from locations array, use tag property of sender button as the index in that array
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
    
    // MARK: - Private methods
    func updateLocations() {
        //        Remove the pins for old Location objects
        mapView.removeAnnotations(locations)
        
        let entity = Location.entity()
        
        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = entity
        
        locations = try! managedObjectContext.fetch(fetchRequest)
        
        // Add a pin for each location on the map
        mapView.addAnnotations(locations)
    }
    
    // Calculate a region and then tell the map view to zoom to that region for Locations
    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
        let region: MKCoordinateRegion
        
        switch annotations.count {
            
        // There are no annotations. Center the map on the user’s current position
        case 0:
            region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            
        // There is only one annotation. Center the map on that one annotation.
        case 1:
            let annotation = annotations[annotations.count - 1]
            
            region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            
        // There are two or more annotations. Calculate the extent of their reach and add a little padding
        default:
            var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            
            for annotation in annotations {
                topLeft.latitude = max(topLeft.latitude,
                                       annotation.coordinate.latitude)
                topLeft.longitude = min(topLeft.longitude,
                                        annotation.coordinate.longitude)
                bottomRight.latitude = min(bottomRight.latitude,
                                           annotation.coordinate.latitude)
                bottomRight.longitude = max(bottomRight.longitude,
                                            annotation.coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2D(latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2,
                                                longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude) / 2)
            
            let extraSpace = 1.1
            let span = MKCoordinateSpan(latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
                                        longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
            
            region = MKCoordinateRegion(center: center, span: span)
        }
        
        return mapView.regionThatFits(region)
    }
}


extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 1. Use is type check operator to determine whether the annotation is a Location object, if not return nil do not make an annotation for any other kind of object
        guard annotation is Location else {
            return nil
        }
        
        // 2. Ask map view to re-use an annotation view object. If it cannot find a recyclable annotation view, create a new one
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            // 3. Configure aesthetic of annotation view
            pinView.isEnabled = true
            pinView.canShowCallout = true
            pinView.animatesDrop = false
            pinView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            
            // 4. Create new UIButton ⓘ, target-action pattern connect “Touch Up Inside” with showLocationDetails()
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.addTarget(self, action: #selector(showLocationDetails), for: .touchUpInside)
            pinView.rightCalloutAccessoryView = rightButton
            
            annotationView = pinView
        }
        
        if let annotationView = annotationView {
            annotationView.annotation = annotation
            
            // 5. Add button to annotation view’s accessory view
            let button = annotationView.rightCalloutAccessoryView as! UIButton
            if let index = locations.index(of: annotation
                as! Location) {
                button.tag = index
            }
        }
        
        return annotationView
    }
}
