//
//  TaskList.swift
//  Todo
//
//  Created by Jake Shelley on 12/1/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import Foundation
import RealmSwift

class TaskList: Object {
    @objc dynamic var id = 0
    @objc dynamic var title = ""
    @objc dynamic var imageNameId = 0 // Default image
    @objc dynamic var colorSchemeId = 0 // Default color scheme
    
    let completedTasks = List<Task>()
    let activeTasks = List<Task>()
    
    func getTotalTasks() -> Int {
        return completedTasks.count + activeTasks.count
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() -> Int {
        let realm = try! Realm()
        return (realm.objects(TaskList.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}
