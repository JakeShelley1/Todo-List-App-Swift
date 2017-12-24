//
//  AppDelegate.swift
//  Todo
//
//  Created by Jake Shelley on 11/27/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.statusBarStyle = .lightContent
        
        let realm = try! Realm()
        try! realm.write { realm.deleteAll() }
        try! realm.write {
            let list = TaskList()
            list.title = "Work"
            list.imageNameId = 1
            list.colorSchemeId = 2
            realm.add(list)
            
            let list2 = TaskList()
            list2.id = list2.incrementID()
            list2.title = "Personal"
            list2.colorSchemeId = 3
            realm.add(list2)
            
            let list3 = TaskList()
            list3.id = list3.incrementID()
            list3.title = "Business"
            list3.colorSchemeId = 4
            realm.add(list3)
            
            let task = Task()
            task.text = "strange that it didn't work"
            
            let task1 = Task()
            task1.text = "Work hard harder"
            
            let task2 = Task()
            task2.text = "weeee"
            
            let task3 = Task()
            task3.text = "weeee"
            
            let task4 = Task()
            task4.text = "weeee"
            
            let task5 = Task()
            task5.text = "weeee"
            
            let task6 = Task()
            task6.text = "weeee"
            
            let task7 = Task()
            task7.text = "weeee"
            
            let task8 = Task()
            task8.text = "weeee"
            
            list.completedTasks.append(task)
            list.activeTasks.append(task1)
            list.activeTasks.append(task2)
            list.activeTasks.append(task3)
            list.completedTasks.append(task4)
            list.completedTasks.append(task5)
            list.completedTasks.append(task6)
            list.activeTasks.append(task7)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

}

