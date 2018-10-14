//
//  Functions.swift
//  MyLocations
//
//  Created by Seth Watson on 10/13/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//

import Foundation

func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}
