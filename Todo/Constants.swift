//
//  Constants.swift
//  Todo
//
//  Created by Jake Shelley on 12/1/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import Foundation
import UIKit

// Sizes
let MINIMIZED_LIST_HEIGHT: CGFloat = 360
let MINIMIZED_LIST_WIDTH: CGFloat = 286
let SAFE_BUFFER: CGFloat = UIDevice().type == .iPhoneX ? 55 : 30

// Duration
let LONG_ANIMATION_DURATION: Double = 0.4
let MEDIUM_ANIMATION_DURATION: Double = 0.2
let SHORT_ANIMATION_DURATION: Double = 0.15

// Color Schemes
let colorSchemes: [[String: UIColor]] = [
    ["primary": .redOrange, "secondary": .orangeRed],
    ["primary": .oceanBlue, "secondary": .babyBlue],
    ["primary": .darkPurple, "secondary": .lightPurple],
    ["primary": .darkGreen, "secondary": .lightGreen],
    ["primary": .shore, "secondary": .sand],
]

// List Icons
let iconImages: [UIImage] = [
    UIImage(named: "checklist")!,
    UIImage(named: "briefcase")!,
    UIImage(named: "person")!,
    UIImage(named: "books")!,
    UIImage(named: "light")!,
]
