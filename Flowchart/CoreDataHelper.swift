//
//  CoreDataHelper.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/19/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class CoreDataHelper: NSObject {
	
	//Singleton access
	class var sharedInstance:CoreDataHelper {
		struct Singleton {
			static let instance = CoreDataHelper()
		}
		
		return Singleton.instance
	}

	let kCoreDataHelperEntity:String = "Peakflow"
	let kCoreDataHelderDateAttribute:String = "datestamp"
	let kCoreDataHelderLatitudeAttribute:String = "location_lat"
	let kCoreDataHelderLongitudeAttribute:String = "location_long"
	let kCoreDataHelderPeakFlowAttribute:String = "peakflow"
	let kCoreDataHelderPuffsAttribute:String = "puffs"
	
	//MARK: CoreData
	func saveCurrentRecord(date:NSDate, location:CLLocation!, flowRate:NSInteger, puffs:NSInteger) {
		let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
		let managedContext = appDelegate.managedObjectContext!
		
		let entity =  NSEntityDescription.entityForName(kCoreDataHelperEntity, inManagedObjectContext: managedContext)
		
		let peakflow = NSManagedObject(entity: entity!, insertIntoManagedObjectContext:managedContext)
		peakflow.setValue(date, forKey: kCoreDataHelderDateAttribute)
		
		var lat:Double = 0.0
		var long:Double = 0.0
		if location != nil {
			lat = location.coordinate.latitude
			long = location.coordinate.longitude
		}
		
		peakflow.setValue(lat, forKey: kCoreDataHelderLatitudeAttribute)
		peakflow.setValue(long, forKey: kCoreDataHelderLongitudeAttribute)
		peakflow.setValue(flowRate, forKey: kCoreDataHelderPeakFlowAttribute)
		peakflow.setValue(puffs, forKey: kCoreDataHelderPuffsAttribute)
		
		var error: NSError?
		if !managedContext.save(&error) {
			let desc = error?.localizedDescription
			NSLog("Error saving coredata: %@", desc!)
			
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Sorry!", comment: "Coredata error - title")
			alertView.message = NSLocalizedString("We were unable to save your flow data.\n\nTake a deep breath. Everything will be OK.", comment: "Coredata error - message")
			alertView.addButtonWithTitle("Dismiss")
			alertView.show()
		}
	}
	
	func peakFlowMovingAverage() -> NSInteger {
		let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
		let managedContext = appDelegate.managedObjectContext!
		
		let fetchRequest = NSFetchRequest(entityName:kCoreDataHelperEntity)
		let dateSort = NSSortDescriptor(key:kCoreDataHelderDateAttribute, ascending:true)
		fetchRequest.sortDescriptors = [dateSort]
		fetchRequest.fetchLimit = 30
		
		var error: NSError?
		let fetchCount:Int = managedContext.countForFetchRequest(fetchRequest, error: &error);
		if (fetchCount > 0) {
			let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?
			if let results:[NSManagedObject] = fetchedResults {
				var result:Int = 0;
				for (index,value:NSManagedObject) in enumerate(results) {
					let current = value.valueForKey("peakflow") as Int
					result += current
				}
				return result/results.count
			}
		}
		
		return 450
	}

}
