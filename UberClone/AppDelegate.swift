//
//  AppDelegate.swift
//  UberClone
//
//  Created by Maria on 5/12/17.
//  Copyright © 2017 Maria Notohusodo. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let configuration = ParseClientConfiguration {
            $0.applicationId = "your own id"
            $0.clientKey = "your own key"
            $0.server = "your own parse server"
        }
        Parse.initialize(with: configuration)
        return true
    }
}

