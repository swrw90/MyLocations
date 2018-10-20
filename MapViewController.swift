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
    var managedObjectContext: NSManagedObjectContext!
    var locations = [Location]()
    
    
    //    MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetches the Location objects and shows them on the map when the view loads
        updateLocations()
    }
    
    
    //MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    
    // MARK: - Actions
    @IBAction func showUser() {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        mapView.setRegion(mapView.regionThatFits(region),animated: true)
    }
    
    @IBAction func showLocations() {
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
}

extension MapViewController: MKMapViewDelegate {
}
