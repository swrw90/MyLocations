//
//  LocationsViewController.swift
//  MyLocations
//
//  Created by Seth Watson on 10/18/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController {
    var managedObjectContext: NSManagedObjectContext!
    
    // Contains a list of Location objects
    var locations = [Location]()
    
    
    //MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tells fetchRequest to look for Location entities
        let fetchRequest = NSFetchRequest<Location>()
        let entity = Location.entity()
        fetchRequest.entity = entity
        
        // Sort by date, Location objects that the user added first will be at the top of the list
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Set locations value to fetch result
        do {
            locations = try
            managedObjectContext.fetch(fetchRequest)
        } catch {
            fatalCoreDataError(error)
        }
    }
    
    //MARK: - Table View Delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell( withIdentifier: "LocationCell", for: indexPath) as! LocationCell
            
            let location = locations[indexPath.row]
            cell.configure(for: location)
            
            return cell
    }
}
