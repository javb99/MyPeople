//
//  AppDelegate.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/8/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationCoordinator: MyPeopleNavigationCoordinator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        navigationCoordinator = MyPeopleNavigationCoordinator()
        
        let myPeopleController = navigationCoordinator.prepareMyPeopleViewController()
        let nav = UINavigationController(rootViewController: myPeopleController)
        nav.navigationBar.prefersLargeTitles = true
        
        window!.rootViewController = nav
        window!.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        navigationCoordinator.stateController.saveIfNeeded()
    }
}

