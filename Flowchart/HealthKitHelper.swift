//
//  HealthKitHelper.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/19/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit
import HealthKit

class HealthKitHelper: NSObject {
	var dateFormatter = NSDateFormatter()

	let healthStore:HKHealthStore = HKHealthStore();
	
	//Singleton access
	class var sharedInstance:HealthKitHelper {
		struct Singleton {
			static let instance = HealthKitHelper()
		}
		
		return Singleton.instance
	}
	
	override init() {
		super.init()
		dateFormatter.dateFormat = "MM/dd/yy hh:mm a"
	}

	func connect() {
		// Set up an HKHealthStore, asking the user for read/write permissions. 
		if (HKHealthStore.isHealthDataAvailable()) {
			let peakFlowType:HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)
			let inhalerUsageType:HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierInhalerUsage)
			let writeTypes = [peakFlowType, inhalerUsageType]

			self.healthStore.requestAuthorizationToShareTypes(NSSet(array:writeTypes), readTypes: nil, completion: {
				(success:Bool, error:NSError!) -> Void in
				
				if (!success) {
					println("HealthKit access denied: " + error.localizedDescription)
					
					var alertView = UIAlertView()
					alertView.title = NSLocalizedString("Sorry", comment: "HealthKit access error - title")
					alertView.message = NSLocalizedString("We were unable to access your data in HealthKit.\n\nYou can correct this in your iPhone Settings under Privacy/Health", comment: "HealthKit access error - message")
					alertView.addButtonWithTitle("Dismiss")
					alertView.show()
				}
			})
		} else {
			println("HealthKit not available on device")
		}
	}
	
	func writePeakFlowValue(flowRate:Int, date:NSDate) {
		let peakUnit = HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit())
		let peakQuantity = HKQuantity(unit:peakUnit, doubleValue:Double(flowRate))
		let peakQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)
		let peakFlowSample = HKQuantitySample(type: peakQuantityType, quantity: peakQuantity, startDate: date, endDate: date)
		
		self.writeSample(peakFlowSample)
	}
	
	func writeInhalerUsage(usage:Int, date:NSDate) {
		let usageUnit = HKUnit.countUnit()
		let usageQuantity = HKQuantity(unit: usageUnit, doubleValue: Double(usage))
		let usageQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierInhalerUsage)
		let usageSample = HKQuantitySample(type: usageQuantityType, quantity: usageQuantity, startDate: date, endDate: date)
		
		self.writeSample(usageSample)
	}
	
	func writeSample(sample:HKQuantitySample) {
		healthStore.saveObject(sample, withCompletion: {
			(success:Bool, error:NSError!) -> Void in
			
			if (!success) {
				println("HealthKit access denied: " + error.localizedDescription)
				
				var alertView = UIAlertView()
				alertView.title = NSLocalizedString("Sorry", comment: "HealthKit access error - title")
				alertView.message = NSLocalizedString("We were unable to access your data in HealthKit.\n\nYou can correct this in your iPhone Settings under Privacy/Health", comment: "HealthKit access error - message")
				alertView.addButtonWithTitle("Dismiss")
				alertView.show()
			}
		})
	}

	func importSamples(records:[[String]]) -> Int {
		var imported = 0
		var columns = []
		for (index,record) in enumerate(records) {
			println(record)
			if index == 0 {
				columns = record
			}
				
			else if record.count == columns.count {
				var dict:Dictionary = NSDictionary(objects:record, forKeys:columns)
				
				//We support: July 8, 2014 8:00 AM
				let dateString:String = dict["date"] as String
				let recordDate = self.dateFormatter.dateFromString(dateString)
				if recordDate == nil {
					return -1;
				}
				
				if let peakFlow:Int = (dict["flowrate"] as String).toInt() {
					self.writePeakFlowValue(peakFlow, date: recordDate!)
				}
				
				if let puffs:Int = (dict["inhaler"] as String).toInt() {
					self.writeInhalerUsage(puffs, date: recordDate!)
				}
				
				++imported

			}
		}
		
		return imported
	}

}