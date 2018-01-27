//
//  TableViewCellExtension.swift
//  manni
//
//  Created by Philipp Matthes on 26.01.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation
import DVB
import Material
import Motion

extension TableViewCell {
    func setUp(forStop stop: Stop) {
        if let region = stop.region {
            self.textLabel?.text = "\(stop.name) (\(region))"
        } else {
            self.textLabel?.text = "\(stop.name)"
        }
        
        self.textLabel?.textColor = UIColor.white
        
        var color = Colors.standardColor()
        if let lineNumber = Int(stop.id) {
            color = Colors.color(forInt: lineNumber)
        }
        self.backgroundColor = color
        self.pulseColor = color.lighter()!
    }
}
