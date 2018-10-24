//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Seth Watson on 10/23/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var childForStatusBarStyle:
        UIViewController? {
        return nil
    }
}
