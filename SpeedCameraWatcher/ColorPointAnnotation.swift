//
//  ColorPointAnnotation.swift
//  SpeedCameraWatcher
//
//  Created by james on 26/12/2016.
//  Copyright © 2016 james. All rights reserved.
//

import UIKit
import MapKit

class ColorPointAnnotation: MKPointAnnotation {
    var pinColor: UIColor
    
    init(pinColor: UIColor) {
        self.pinColor = pinColor
        super.init()
    }
}
