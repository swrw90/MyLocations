//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by Seth Watson on 10/13/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//
//

import Foundation
import CoreData
import CoreLocation
import UIKit

extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var category: String
    @NSManaged var date: Date
    @NSManaged public var latitude: Double
    @NSManaged public var locationDescription: String
    @NSManaged public var longitude: Double
    @NSManaged var placemark: CLPlacemark?
    @NSManaged public var photoID: NSNumber?

    
}
