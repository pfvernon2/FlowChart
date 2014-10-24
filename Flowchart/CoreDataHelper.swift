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
	var dateFormatter = NSDateFormatter()

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
	
	override init() {
		super.init()
		//cache date formatter for performance
		dateFormatter.dateFormat = "MM/dd/yy hh:mm a"
	}
	
	//MARK: CoreData
	func saveRecord(date:NSDate, flowRate:NSInteger, puffs:NSInteger, location:CLLocation?) -> Bool {
		let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
		let managedContext = appDelegate.managedObjectContext!
		
		let entity =  NSEntityDescription.entityForName(kCoreDataHelperEntity, inManagedObjectContext: managedContext)
		
		let peakflow = NSManagedObject(entity: entity!, insertIntoManagedObjectContext:managedContext)
		peakflow.setValue(date, forKey: kCoreDataHelderDateAttribute)
		
		var lat:Double = 0.0
		var long:Double = 0.0
		if location != nil {
			lat = location!.coordinate.latitude
			long = location!.coordinate.longitude
		}
		
		peakflow.setValue(lat, forKey: kCoreDataHelderLatitudeAttribute)
		peakflow.setValue(long, forKey: kCoreDataHelderLongitudeAttribute)
		peakflow.setValue(flowRate, forKey: kCoreDataHelderPeakFlowAttribute)
		peakflow.setValue(puffs, forKey: kCoreDataHelderPuffsAttribute)
		
		var error: NSError?
		if !managedContext.save(&error) {
			let desc = error?.localizedDescription
			NSLog("Error saving coredata: %@", desc!)
			
			return false
		}
		
		return true
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
				var count:Int = 0;
				for (index,value:NSManagedObject) in enumerate(results) {
					let current = value.valueForKey("peakflow") as Int
					//ignore 0 values, missing records
					if current > 0 {
						result += current
						++count
					}
				}
				return result/count
			}
		}
		
		return 450
	}

	func peakFlowMax() -> NSInteger {
		let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
		let managedContext = appDelegate.managedObjectContext!
		
		let fetchRequest = NSFetchRequest(entityName:kCoreDataHelperEntity)
		let peakSort = NSSortDescriptor(key:kCoreDataHelderPeakFlowAttribute, ascending:false)
		fetchRequest.sortDescriptors = [peakSort]
		fetchRequest.fetchLimit = 1
		
		var error: NSError?
		let fetchCount:Int = managedContext.countForFetchRequest(fetchRequest, error: &error);
		if (fetchCount > 0) {
			let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?
			if let results:[NSManagedObject] = fetchedResults {
				let result:Int = results[0].valueForKey("peakflow") as Int
				return result
			}
		}
		
		return 0
	}

	func importRecord(dict:Dictionary<NSObject,AnyObject>) -> Bool {
		//We support: July 8, 2014 8:00 AM
		let dateString:String = dict["date"] as String
		let recordDate = self.dateFormatter.dateFromString(dateString)
		if recordDate == nil {
			return false;
		}
		
		let flowRate:Int = NSString(string: dict["flowrate"] as String).integerValue
		let puffs:Int = NSString(string: dict["inhaler"] as String).integerValue
		let lat:Double = NSString(string: dict["latitude"] as String).doubleValue
		let long:Double = NSString(string: dict["longitude"] as String).doubleValue
		var location:CLLocation? = nil
		
		if lat != 0.0 || long != 0.0 {
			location = CLLocation(latitude: lat, longitude: long)
		}

		return self.saveRecord(recordDate!, flowRate:flowRate, puffs:puffs, location:location)
	}
	
	func importData(records:[[String]]) -> Int {
		let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
		let managedContext = appDelegate.managedObjectContext!
		
		var imported = 0
		var columns = []
		managedContext.undoManager?.beginUndoGrouping()
		for (index,record) in enumerate(records) {
			#if DEBUG
				println(record)
			#endif
			
			if index == 0 {
				columns = record
			}
			
			else if record.count == columns.count {
				++imported
				var dict:Dictionary = NSDictionary(objects:record, forKeys:columns)
				if !self.importRecord(dict) {
					managedContext.undoManager?.undo()
					return -1
				}
			}
		}
		managedContext.undoManager?.endUndoGrouping()
		
		return imported
	}
}
