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
    @IBOutlet weak var mapView: MKMapView!
    
    var managedObjectContext: NSManagedObjectContext!
    
    // MARK:- Actions
    @IBAction func showUser() {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
       
        mapView.setRegion(mapView.regionThatFits(region),animated: true)
    }
    
    @IBAction func showLocations() {
    }
}

extension MapViewController: MKMapViewDelegate {
}
