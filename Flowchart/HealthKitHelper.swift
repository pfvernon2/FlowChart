//
//  HealthKitHelper.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/19/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit
import HealthKit
import CoreLocation

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
			let readTypes = [peakFlowType, inhalerUsageType]

			self.healthStore.requestAuthorizationToShareTypes(NSSet(array:writeTypes), readTypes: NSSet(array:readTypes), completion: {
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
	
	// MARK: - write
	
	func locationToMetadata(location:CLLocation?) -> Dictionary<String, NSNumber>? {
		var lat:Double = 0.0
		var long:Double = 0.0
		if location != nil {
			lat = location!.coordinate.latitude
			long = location!.coordinate.longitude
			return ["com.cyberdev.flowchart.latitude":lat as NSNumber, "com.cyberdev.flowchart.longitude":long as NSNumber]
		}
		
		return nil
	}
	
	func writePeakFlowSample(flowRate:Int, date:NSDate, location:CLLocation!, completion:(success:Bool, error:NSError!)->()) {
		let peakUnit = HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit())
		let peakQuantity = HKQuantity(unit:peakUnit, doubleValue:Double(flowRate))
		let peakQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)
		let metadata = self.locationToMetadata(location)
		
		let peakFlowSample = HKQuantitySample(type: peakQuantityType, quantity: peakQuantity, startDate: date, endDate: date, metadata:metadata)
		
		self.writeSample(peakFlowSample, completion)
	}
	
	func writeInhalerUsage(usage:Int, date:NSDate, location:CLLocation!, completion:(success:Bool, error:NSError!)->()) {
		let usageUnit = HKUnit.countUnit()
		let usageQuantity = HKQuantity(unit: usageUnit, doubleValue: Double(usage))
		let usageQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierInhalerUsage)
		let metadata = self.locationToMetadata(location)
		
		let usageSample = HKQuantitySample(type: usageQuantityType, quantity: usageQuantity, startDate: date, endDate: date, metadata:metadata)
		
		self.writeSample(usageSample, completion)
	}
	
	func writeSample(sample:HKQuantitySample, completion:(success:Bool, error:NSError!)->()) {
		healthStore.saveObject(sample, withCompletion: {
			(success:Bool, error:NSError!) -> Void in
			if (!success) {
				println("HealthKit access denied: " + error.localizedDescription)
			}
			
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				completion(success: success, error: error)
			})
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
					self.writePeakFlowSample(peakFlow, date: recordDate!, location: nil, completion: { (success, error) -> () in
					})
				}
				
				if let puffs:Int = (dict["inhaler"] as String).toInt() {
					self.writeInhalerUsage(puffs, date: recordDate!, location: nil, completion: { (success, error) -> () in
					})
				}
				
				++imported
				
			}
		}
		
		return imported
	}
	
	// MARK: - read
	
	func getMaxPeakFlowSample(completion:(peakFlow:Double, error:NSError!)->()) {
		let peakQuantityType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)
		
		let statsQuery = HKStatisticsQuery(quantityType: peakQuantityType, quantitySamplePredicate: nil, options: .DiscreteMax) { (query, statistics, error:NSError!) -> Void in
			
			let peakUnit = HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit())
			let peakQuantity:HKQuantity = statistics.maximumQuantity()
			let result = peakQuantity.doubleValueForUnit(peakUnit)
			
			completion(peakFlow:result, error:error)
		}
		
		healthStore.executeQuery(statsQuery)
	}
	
	func getMinPeakFlowSample(completion:(peakFlow:Double, error:NSError!)->()) {
		let peakQuantityType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)
		
		let statsQuery = HKStatisticsQuery(quantityType: peakQuantityType, quantitySamplePredicate: nil, options: .DiscreteMin) { (query, statistics, error:NSError!) -> Void in
			
			let peakUnit = HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit())
			let peakQuantity:HKQuantity = statistics.minimumQuantity()
			let result = peakQuantity.doubleValueForUnit(peakUnit)
			
			completion(peakFlow:result, error:error)
		}
		
		healthStore.executeQuery(statsQuery)
	}

	func getPeakFlowMovingAverage(completion:(peakFlow:Double, error:NSError!)->()) {
		let past:NSDate = NSDate(timeIntervalSinceNow: -(60.0 * 60.0 * 24 * 30))
		let now:NSDate = NSDate()
		let datePredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate: now, options: .None)
		let peakQuantityType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)
		
		let statsQuery = HKStatisticsQuery(quantityType: peakQuantityType, quantitySamplePredicate: datePredicate, options: .DiscreteAverage) { (query, statistics, error:NSError!) -> Void in
			
			let peakUnit = HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit())
			let peakQuantity:HKQuantity = statistics.averageQuantity()
			let result = peakQuantity.doubleValueForUnit(peakUnit)
			
			completion(peakFlow:result, error:error)
		}
		
		healthStore.executeQuery(statsQuery)
	}
	
	func exportPeakFlowSamples(completion:(peakFlow: [HKQuantitySample], error:NSError!)->()){
		let past:NSDate = NSDate.distantPast() as NSDate
		let future:NSDate = NSDate.distantFuture() as NSDate
		let datePredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate: future, options: .None)
		
		let peakQuantityType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)
		var peakResults = [HKQuantitySample]()
		let peakQuery = HKSampleQuery(sampleType: peakQuantityType, predicate: datePredicate,
			limit: 0, sortDescriptors: nil, resultsHandler: {
				(query, results, error) in
				
				if (error == nil) {
					peakResults = results as [HKQuantitySample]
				}
				
				completion(peakFlow:peakResults, error:error)
		})
		healthStore.executeQuery(peakQuery)
	}
	
	func exportInhalerSamples(completion:(inhaler: [HKQuantitySample], error:NSError!)->()) {
		let past:NSDate = NSDate.distantPast() as NSDate
		let future:NSDate = NSDate.distantFuture() as NSDate
		let datePredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate: future, options: .None)

		let inhalerQuantityType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierInhalerUsage)
		var inhalerResults = [HKQuantitySample]()
		let inhalerQuery = HKSampleQuery(sampleType: inhalerQuantityType, predicate: datePredicate,
			limit: 0, sortDescriptors: nil, resultsHandler: {
				(query, results, error) in
				
				if (error == nil) {
					inhalerResults = results as [HKQuantitySample]
				}

				completion(inhaler:inhalerResults, error:error)
		})
		healthStore.executeQuery(inhalerQuery)
	}
	
	func exportSamples(completion:(peakFlow:[[String]], inhaler:[[String]], error:NSError!)->()) {
		//background export process
		let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
		dispatch_async(dispatch_get_global_queue(priority, 0)) {
			//create group so we can join operations
			let hkGroup:dispatch_group_t  = dispatch_group_create();
			
			//export Peak Flow
			var peakFlowData:[[String]] = [[String]]()
			var peakFlowError:NSError!
			dispatch_group_enter(hkGroup);
			self.exportPeakFlowSamples { (peakFlow, error) -> () in
				peakFlowError = error
				
				//write headers
				// TODO: - localization issues
				peakFlowData.append(["type", "date", "value", "units", "metadata"])
				
				//ensure units are l/min
				let peakUnit = HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit())
				let peakUnitString = peakUnit.unitString
				let peakQuantityDescriptor = HKQuantityTypeIdentifierPeakExpiratoryFlowRate.stringByReplacingOccurrencesOfString("HKQuantityTypeIdentifier",
					withString: "")
				for (index, sample) in enumerate(peakFlow) {
					let date = sample.startDate
					let flowRate = sample.quantity.doubleValueForUnit(peakUnit);
					var metadataString = ""
					if let metadata = sample.metadata {
						metadataString =  "\(metadata)"
					}
					
					peakFlowData.append([peakQuantityDescriptor, date.description, "\(flowRate)", peakUnitString, metadataString])
					
					println(sample.metadata)
				}
				
				dispatch_group_leave(hkGroup);
			}
			
			//Export Inhaler
			var inhalerData:[[String]] = [[String]]()
			var inhalerError:NSError!
			dispatch_group_enter(hkGroup);
			self.exportInhalerSamples { (inhaler, error) -> () in
				inhalerError = error
				
				//write headers
				// TODO: - localization issues
				inhalerData.append(["type", "date", "value", "units", "metadata"])
				
				//ensure units are counts (probably always will be)
				let inhalerUnit = HKUnit.countUnit()
				let inhalerUnitString = inhalerUnit.unitString
				let inhalerQuantityDescriptor = HKQuantityTypeIdentifierInhalerUsage.stringByReplacingOccurrencesOfString("HKQuantityTypeIdentifier",
					withString: "")
				for (index, sample) in enumerate(inhaler) {
					let date = sample.startDate
					let count = sample.quantity.doubleValueForUnit(inhalerUnit);
					var metadataString = ""
					if let metadata = sample.metadata {
						metadataString =  "\(metadata)"
					}
					
					inhalerData.append([inhalerQuantityDescriptor, date.description, "\(count)", inhalerUnitString, metadataString])
				}
				
				dispatch_group_leave(hkGroup);
			}
			
			//Join workers and switch to main thread for error handling -or- completion
			dispatch_group_notify(hkGroup, dispatch_get_main_queue(), {
				//report one of the errors, if any
				var resultError = peakFlowError
				if resultError == nil {
					resultError = inhalerError
				}
				
				completion(peakFlow: peakFlowData, inhaler: inhalerData, error:resultError)
			})
		}
	}
}






