//
//  CategoryPickerViewController.swift
//  MyLocations
//
//  Created by Seth Watson on 10/12/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//

import UIKit


class CategoryPickerViewController: UITableViewController {
    var selectedCategoryName = ""
    var selectedIndexPath = IndexPath()
    
    let categories = ["No Category", "Apple Store", "Bar", "Bookstore", "Club", "Grocery Store", "Historic Building", "House", "Icecream Vendor", "Landmark", "Park"]
    
    
    //MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for i in 0..<categories.count {
            if categories[i] == selectedCategoryName {
                selectedIndexPath = IndexPath(row: i, section: 0)
                break
            }
        }
    }
    
    //MARK: Table View Delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
}
