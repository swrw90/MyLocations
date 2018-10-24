//
//  String+AddText.swift
//  MyLocations
//
//  Created by Seth Watson on 10/23/18.
//  Copyright © 2018 Seth Watson. All rights reserved.
//

extension String {
    mutating func add(text: String?, separatedBy separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}
