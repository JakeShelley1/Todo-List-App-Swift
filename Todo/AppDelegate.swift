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

    private let USER_HAS_BEEN_ONBOARDED = "USER_HAS_BEEN_ONBOARDED"
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.statusBarStyle = .lightContent

        let realm = try! Realm()
        let defaults = UserDefaults.standard
        
        // If the user has never been onboarded and they don't have any lists, create the onboarding list
        if (!defaults.bool(forKey: USER_HAS_BEEN_ONBOARDED) &&
            realm.objects(TaskList.self).count == 0) {
            buildOnboardingList()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

    private func buildOnboardingList() {
        let realm = try! Realm()
        try! realm.write {
            let defaultList = TaskList()
            defaultList.title = "Swipe Up"
            defaultList.imageNameId = 1
            defaultList.colorSchemeId = 0
            realm.add(defaultList)
            
            let task0 = Task()
            task0.text = "Tap a task for detail"
            task0.note = "Tapping a task will bring up its detail page. You can edit the title and the note of a task. This is also where you can delete a task by clicking the trash in the upper right hadn corner."
            
            let task1 = Task()
            task1.text = "Adding a task"
            task1.note = "Click the plus button in the list page (the screen you were just on) to add a task."
            
            let task2 = Task()
            task2.text = "Creating a new list"
            task2.note = "On the Home page, swipe right to get to the outline of a list. Click inside the outline and you can create a new list. You can create as many as you'd like!"
            
            let task3 = Task()
            task3.text = "Edit a list"
            task3.note = "On the home page, click the three vertical dots on the right hand corner of a list to begin editing. You can change the icon, color, and the name of a list. You can also delete a list from the edit screen."
            
            let task4 = Task()
            task4.text = "Reorder list"
            task4.note = "You can reorder lists by clicking the image of an up and down arrow in the top right corner of the list page."
            
            defaultList.activeTasks.append(objectsIn: [task0, task1, task2, task3, task4])
            UserDefaults.standard.set(true, forKey: USER_HAS_BEEN_ONBOARDED)
        }
    }
    
}

