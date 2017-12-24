//
//  Task.swift
//  Todo
//
//  Created by Jake Shelley on 11/27/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import Foundation
import RealmSwift

class Task: Object {
    
    @objc dynamic var text = ""
    @objc dynamic var dueDate = Date(timeIntervalSince1970: 1)
    @objc dynamic var note = ""
    
}
