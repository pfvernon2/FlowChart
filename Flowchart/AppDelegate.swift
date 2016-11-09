//
//  AppDelegate.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/17/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		//Make it easy to find our documents directory in the simulator
#if TARGET_IPHONE_SIMULATOR
		let docDir:NSURL = self.applicationDocumentsDirectory
		println(docDir)
#endif
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
		
		LocationHelper.sharedInstance.stop()
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		
		let trackLocation:Bool = LocationHelper.sharedInstance.trackLocationPref
		if trackLocation {
			LocationHelper.sharedInstance.start()
		}
		
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
	}

	lazy var applicationDocumentsDirectory: URL = {
		// The directory the application uses to store the Core Data store file. This code uses a directory named "com.cyberdev.Flowchart" in the application's documents Application Support directory.
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls[urls.count-1] 
	}()

	func appNameAndVersionNumberDisplayString() -> String {
		let infoDictionary:[AnyHashable: Any] = Bundle.main.infoDictionary!
		let appDisplayName:String? = infoDictionary["CFBundleName"] as? String
		let majorVersion:String? = infoDictionary["CFBundleShortVersionString"] as? String
		let minorVersion:String? = infoDictionary["CFBundleVersion"] as? String

		return String(format: "%@, Version %@ (%@)", appDisplayName!, majorVersion!, minorVersion!)
	}
}

