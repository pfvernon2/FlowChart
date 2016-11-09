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
	var dateFormatter = DateFormatter()

	let healthStore:HKHealthStore = HKHealthStore()
	
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

	func connect(_ completion:@escaping (_ success:Bool, _ error:NSError?)->()) -> Bool {
		// Set up an HKHealthStore, asking the user for read/write permissions. 
		if (HKHealthStore.isHealthDataAvailable()) {
			let peakFlowType:HKQuantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.peakExpiratoryFlowRate)!
			let inhalerUsageType:HKQuantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.inhalerUsage)!
			let writeTypes = [peakFlowType, inhalerUsageType]
			let readTypes = [peakFlowType, inhalerUsageType]
            
			self.healthStore.requestAuthorization(toShare: NSSet(array:writeTypes) as? Set<HKSampleType>,
				read: NSSet(array:readTypes)as? Set<HKObjectType>,
				completion:
				{
				(success:Bool, error:NSError?) -> Void in
				if error != nil {
					print("HealthKit access denied: " + error!.localizedDescription)
				}
				completion(success, error)
			} as! (Bool, Error?) -> Void)
		} else {
			print("HealthKit not available on device")
			return false
		}
		
		return true
	}
	
	// MARK: - write
	func locationToMetadata(_ location:CLLocation?) -> Dictionary<String, NSNumber>? {
		var lat:Double = 0.0
		var long:Double = 0.0
		if location != nil {
			lat = location!.coordinate.latitude
			long = location!.coordinate.longitude
			return ["com.cyberdev.flowchart.latitude":lat as NSNumber, "com.cyberdev.flowchart.longitude":long as NSNumber]
		}
		
		return nil
	}
	
	func writePeakFlowSample(_ flowRate:Double, date:Date, location:CLLocation!, completion:@escaping (_ success:Bool, _ error:NSError?)->()) {
		let peakUnit = HKUnit.liter().unitDivided(by: HKUnit.minute())
		let peakQuantity = HKQuantity(unit:peakUnit, doubleValue:flowRate)
		let peakQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.peakExpiratoryFlowRate)
		let metadata = self.locationToMetadata(location)
		
		let peakFlowSample = HKQuantitySample(type: peakQuantityType!, quantity: peakQuantity, start: date, end: date, metadata:metadata)
		
		self.writeSample(peakFlowSample, completion: completion)
	}
	
	func writeInhalerUsage(_ usage:Double, date:Date, location:CLLocation!, completion:@escaping (_ success:Bool, _ error:NSError?)->()) {
		let usageUnit = HKUnit.count()
		let usageQuantity = HKQuantity(unit: usageUnit, doubleValue:usage)
		let usageQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.inhalerUsage)
		let metadata = self.locationToMetadata(location)
		
		let usageSample = HKQuantitySample(type: usageQuantityType!, quantity: usageQuantity, start: date, end: date, metadata:metadata)
		
		self.writeSample(usageSample, completion: completion)
	}
	
	func writeSample(_ sample:HKQuantitySample, completion:@escaping (_ success:Bool, _ error:NSError?)->()) {
		healthStore.save(sample, withCompletion: { (success, error) in
			if (!success) {
				print("HealthKit access denied: " + error!.localizedDescription)
			}
			
			DispatchQueue.main.async(execute: { () -> Void in
				completion(success, error as NSError?)
			})
		})
	}

	func importSamples(_ records:[[String]], completion:@escaping (_ count:Int)->()) {
		var imported = 0
		var columns = [String]()
		
		let lock:NSLock = NSLock()
		let hkGroup:DispatchGroup = DispatchGroup();
		
		for (index,record) in records.enumerated() {
			print(record)
			if index == 0 {
				//check min required headers
				if record.contains("type") &&
					record.contains("date") &&
					record.contains("value")
				{
					columns = record as [String]
				} else {
					break
				}
			}
				
			else if record.count == columns.count {
				let dict:NSDictionary = NSDictionary(objects:record, forKeys:columns as [NSCopying])
				
				//We support: July 8, 2014 8:00 AM
				let dateString:String = dict["date"] as! String
				let recordDate = self.dateFormatter.date(from: dateString)
				if recordDate == nil {
					continue;
				}
				
				let currType:String = dict["type"] as! String
				let currValue:Double = NumberFormatter().number(from: dict["value"] as! String)!.doubleValue
				
				if let currMetadata:String = dict["metadata"] as? String {
					// TODO: - Import lat/long metadata... might want to change export to make it easier on ourselves
					if currMetadata.characters.count > 0 {
						print(currMetadata)
					}
				}
				
                switch currType {
                case HKQuantityTypeIdentifier.peakExpiratoryFlowRate.rawValue:
                    hkGroup.enter();
                    self.writePeakFlowSample(currValue, date: recordDate!, location: nil, completion: { (success, error) -> () in
                        if success {
                            lock.lock()
                            imported += 1
                            lock.unlock()
                        }
                        hkGroup.leave();
                    })
                    
                case HKQuantityTypeIdentifier.inhalerUsage.rawValue:
                    hkGroup.enter();
                    self.writeInhalerUsage(currValue, date: recordDate!, location: nil, completion: { (success, error) -> () in
                        if success {
                            lock.lock()
                            imported += 1
                            lock.unlock()
                        }
                        hkGroup.leave();
                    })
                default:
                    break
                }
			}
		}
		
		hkGroup.notify(queue: DispatchQueue.main, execute: {
			completion(imported)
		})
	}
	
	// MARK: - Read
	// MARK: - Peak Flow Queries
	func getMaxPeakFlowSample(_ completion:@escaping (_ peakFlow:Double, _ error:NSError?)->()) {
		let peakQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.peakExpiratoryFlowRate)
		
		let statsQuery = HKStatisticsQuery(quantityType: peakQuantityType!, quantitySamplePredicate: nil, options: .discreteMax) { (query, statistics, error) -> Void in
			
			var result = 0.0
			if statistics != nil {
				let peakUnit = HKUnit.liter().unitDivided(by: HKUnit.minute())
				if let peakQuantity:HKQuantity = statistics!.maximumQuantity() {
					result = peakQuantity.doubleValue(for: peakUnit)
				}
			}
			
			completion(result, error as NSError?)
		}
		
		healthStore.execute(statsQuery)
	}
	
	func getMinPeakFlowSample(_ completion:@escaping (_ peakFlow:Double, _ error:NSError?)->()) {
		let peakQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.peakExpiratoryFlowRate)
		
		let statsQuery = HKStatisticsQuery(quantityType: peakQuantityType!, quantitySamplePredicate: nil, options: .discreteMin) { (query, statistics, error) -> Void in
			
			var result = 0.0
			if statistics != nil {
				let peakUnit = HKUnit.liter().unitDivided(by: HKUnit.minute())
				if let peakQuantity:HKQuantity = statistics!.minimumQuantity() {
					result = peakQuantity.doubleValue(for: peakUnit)
				}
			}
			
			completion(result, error as NSError?)
		}
		
		healthStore.execute(statsQuery)
	}

	func getPeakFlowAverageWithPredicate(_ predicate:NSPredicate!, completion:@escaping (_ peakFlow:Double, _ error:NSError?)->()) {
		let peakQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.peakExpiratoryFlowRate)
		
		let statsQuery = HKStatisticsQuery(quantityType: peakQuantityType!, quantitySamplePredicate: predicate, options: .discreteAverage) { (query, statistics, error) -> Void in
			
			var result = 0.0
			if statistics != nil {
				let peakUnit = HKUnit.liter().unitDivided(by: HKUnit.minute())
				if let peakQuantity:HKQuantity = statistics!.averageQuantity() {
					result = peakQuantity.doubleValue(for: peakUnit)
				}
			}
			
			completion(result, error as NSError?)
		}
		
		healthStore.execute(statsQuery)
	}

	func getPeakFlowAverageForLastMonth(_ completion:@escaping (_ peakFlow:Double, _ error:NSError?)->()) {
		let past:Date = Date(timeIntervalSinceNow: -(60.0 * 60.0 * 24 * 30))
		let now:Date = Date()
		let datePredicate = HKQuery.predicateForSamples(withStart: past, end: now, options: HKQueryOptions())
		
		self.getPeakFlowAverageWithPredicate(datePredicate, completion: completion)
	}
	
	func getPeakFlowAverage(_ completion:@escaping (_ peakFlow:Double, _ error:NSError?)->()) {
		self.getPeakFlowAverageWithPredicate(nil, completion: completion)
	}
	
	func exportPeakFlowSamples(_ completion:@escaping (_ peakFlow: [HKQuantitySample], _ error:NSError?)->()){
		let past:Date = Date.distantPast 
		let future:Date = Date.distantFuture 
		let datePredicate = HKQuery.predicateForSamples(withStart: past, end: future, options: HKQueryOptions())
		
		let peakQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.peakExpiratoryFlowRate)
		var peakResults = [HKQuantitySample]()
		let peakQuery = HKSampleQuery(sampleType: peakQuantityType!, predicate: datePredicate,
			limit: 0, sortDescriptors: nil, resultsHandler: {
				(query, results, error) in
				
				if (error == nil) {
					peakResults = results as! [HKQuantitySample]
				}
				
				completion(peakResults, error as NSError?)
		})
		healthStore.execute(peakQuery)
	}
	
	// MARK: - Inhaler Queries
	func getInhalerDailyAverageWithPredicate(_ predicate:NSPredicate!, completion:@escaping (_ inhaler:Double, _ error:NSError?)->()) {
		let inhalerQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.inhalerUsage)
		
		let statsQuery = HKStatisticsQuery(quantityType: inhalerQuantityType!, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, statistics, error) -> Void in
			
			var result = 0.0
			if statistics != nil {
				let countUnit = HKUnit.count()
				if let inhalerCount:HKQuantity = statistics!.sumQuantity() {
					//get cummulative counts for query
					result = inhalerCount.doubleValue(for: countUnit)
					
					//get days between result dates
                    if let startDate:Date = (statistics!.startDate as NSDate).copy() as? Date, let endDate:Date = (statistics!.endDate as NSDate).copy() as? Date {
                        let components = Calendar.current.dateComponents([Calendar.Component.day], from: startDate, to: endDate)
                        let days:Double = Double(components.day!)
                        if days > 0.0 {
                            result /= days
                        }
                    }
				}
			}
			
			completion(result, error as NSError?)
		}
		
		healthStore.execute(statsQuery)
	}
	
	func getInhalerDailyAverageForLastMonth(_ completion:@escaping (_ inhaler:Double, _ error:NSError?)->()) {
		let past:Date = Date(timeIntervalSinceNow: -(60.0 * 60.0 * 24 * 30))
		let now:Date = Date()
		let datePredicate = HKQuery.predicateForSamples(withStart: past, end: now, options: HKQueryOptions())
		
		self.getInhalerDailyAverageWithPredicate(datePredicate, completion: completion);
	}
	
	func getInhalerAverage(_ completion:@escaping (_ inhaler:Double, _ error:NSError?)->()) {
		self.getInhalerDailyAverageWithPredicate(nil, completion: completion)
	}
	
	func exportInhalerSamples(_ completion:@escaping (_ inhaler: [HKQuantitySample], _ error:NSError?)->()) {
		let past:Date = Date.distantPast 
		let future:Date = Date.distantFuture 
		let datePredicate = HKQuery.predicateForSamples(withStart: past, end: future, options: HKQueryOptions())

		let inhalerQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.inhalerUsage)
		var inhalerResults = [HKQuantitySample]()
		let inhalerQuery = HKSampleQuery(sampleType: inhalerQuantityType!, predicate: datePredicate,
			limit: 0, sortDescriptors: nil, resultsHandler: {
				(query, results, error) in
				
				if (error == nil) {
					inhalerResults = results as! [HKQuantitySample]
				}

				completion(inhalerResults, error as NSError?)
		})
		healthStore.execute(inhalerQuery)
	}
	
	func exportSamples(_ completion:@escaping (_ peakFlow:[[String]], _ inhaler:[[String]], _ error:NSError?)->()) {
		//background export process
		DispatchQueue.global().async {
			//create group so we can join operations
			let hkGroup:DispatchGroup = DispatchGroup();
			
			//export Peak Flow
			var peakFlowData:[[String]] = [[String]]()
			var peakFlowError:NSError!
			hkGroup.enter();
			self.exportPeakFlowSamples { (peakFlow, error) -> () in
				peakFlowError = error
				
				//write headers
				peakFlowData.append(["type", "date", "value", "units", "metadata"])
				
				//ensure units are l/min
				let peakUnit = HKUnit.liter().unitDivided(by: HKUnit.minute())
				let peakUnitString = peakUnit.unitString
				let peakQuantityDescriptor = HKQuantityTypeIdentifier.peakExpiratoryFlowRate
				for (_, sample) in peakFlow.enumerated() {
					let date = self.dateFormatter.string(from: sample.startDate)
					let flowRate = sample.quantity.doubleValue(for: peakUnit);
					var metadataString = ""
					if let metadata = sample.metadata {
						metadataString =  "\(metadata)"
					}
					
					peakFlowData.append([peakQuantityDescriptor.rawValue, date, "\(flowRate)", peakUnitString, metadataString])
					
					print(sample.metadata ?? "missing sample")
				}
				
				hkGroup.leave();
			}
			
			//Export Inhaler
			var inhalerData:[[String]] = [[String]]()
			var inhalerError:NSError!
			hkGroup.enter();
			self.exportInhalerSamples { (inhaler, error) -> () in
				inhalerError = error
				
				//write headers
				inhalerData.append(["type", "date", "value", "units", "metadata"])
				
				//ensure units are counts (probably always will be)
				let inhalerUnit = HKUnit.count()
				let inhalerUnitString = inhalerUnit.unitString
				let inhalerQuantityDescriptor = HKQuantityTypeIdentifier.inhalerUsage
				for (_, sample) in inhaler.enumerated() {
					let date = self.dateFormatter.string(from: sample.startDate)
					let count = sample.quantity.doubleValue(for: inhalerUnit);
					var metadataString = ""
					if let metadata = sample.metadata {
						metadataString =  "\(metadata)"
					}
					
					inhalerData.append([inhalerQuantityDescriptor.rawValue, date, "\(count)", inhalerUnitString, metadataString])
				}
				
				hkGroup.leave();
			}
			
			//Join workers and switch to main thread for error handling -or- completion
			hkGroup.notify(queue: DispatchQueue.main, execute: {
				//report one of the errors, if any
				var resultError = peakFlowError
				if resultError == nil {
					resultError = inhalerError
				}
				
				completion(peakFlowData, inhalerData, resultError)
			})
		}
	}
}






