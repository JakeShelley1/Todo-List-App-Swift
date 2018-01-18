//
//  UIDevice+Todo.swift
//  Todo
//
//  Created by Jake Shelley on 12/10/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import Foundation
import UIKit

enum Model {
    case iPhoneX
    case notIPhoneX
}

extension UIDevice {
    
    var type: Model {
        // TODO - Think of better way to determine device type
        // NOTE - That slack overflow answer is NOT future proof! Failed on certain devices.
        return UIScreen.main.bounds.height == 812 ? .iPhoneX : .notIPhoneX
    }
    
}
