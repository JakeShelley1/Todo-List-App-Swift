//
//  UIView+Todo.swift
//  Todo
//
//  Created by Jake Shelley on 12/1/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addSubviews(_ views: [UIView]) {
        for view in views {
            self.addSubview(view)
        }
    }
}
