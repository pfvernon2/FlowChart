//
//  LocationHelper.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/19/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit
import CoreLocation

//MARK: Constants
let kLocationUserPref:String = "trackLocation"
let kLocationHelperNotification:String = "com.cyberdev.LocationHelper.kLocationHelperNotification"
let kMinDistanceUpdateMeters:Double = 500

class LocationHelper: NSObject, CLLocationManagerDelegate {

	//Singleton access
	class var sharedInstance:LocationHelper {
		struct Singleton {
			static let instance = LocationHelper()
		}
		
		return Singleton.instance
	}

	override init() {
		super.init()
		self.trackLocationPref = self.getUserLocationTrackingUserPref()
	}
	
	//MARK: Variables
	var locationManager : CLLocationManager!
	var authorizationStatus : CLAuthorizationStatus!
	var lastPlacemark : CLPlacemark!
	var locationResolved : Bool = false
	var accessAuthorized : Bool = false
	var trackLocationPref : Bool = false

	//MARK: Utilities
	func setUserLocationTrackingUserPref(enableTracking:Bool) {
		var userDefaults = NSUserDefaults.standardUserDefaults()
		userDefaults.setBool(enableTracking, forKey:kLocationUserPref)
		userDefaults.synchronize()
		
		self.trackLocationPref = self.getUserLocationTrackingUserPref()
		
		if enableTracking {
			self.start()
		} else {
			self.stop()
		}
	}
	
	func getUserLocationTrackingUserPref() -> Bool {
		var userDefaults = NSUserDefaults.standardUserDefaults()
		userDefaults.synchronize()
		var trackLocation:Bool = userDefaults.boolForKey(kLocationUserPref)
		return trackLocation
	}
	
	func displayPlacemark() -> String {
		let address:String? = lastPlacemark.subThoroughfare
		let street:String? = lastPlacemark.thoroughfare
		let city:String? = lastPlacemark.locality
		let state:String? = lastPlacemark.administrativeArea
		
		var description:String = ""
		if address != nil && street != nil {
			description = address! + " " + street!;
		}
		
		if city != nil {
			if count(description) > 0 {
				description += ", "
			}
			description += city!
		}
		
		if state != nil {
			if count(description) > 0 {
				description += ", "
			}
			description += state!
		}
		
		if count(description) > 0 {
			description += "\n"
		}
		description += "(" + displayLocation() + ")"
		
		return description
	}
	
	func displayLocation() -> String {
		let lat = String(format: "%.8f", arguments:[locationManager.location.coordinate.latitude])
		let long = String(format: "%.8f", arguments:[locationManager.location.coordinate.longitude])
		let description = lat + ", " + long
		return description
	}
	
	//MARK: Lifecycle
	func start() {
		//start location manager
		locationManager = CLLocationManager()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.distanceFilter = kMinDistanceUpdateMeters
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
	}
	
	func stop() {
		if locationManager != nil {
			locationManager.stopUpdatingLocation()
		}
	}
	
	//MARK: CLLocationManagerDelegate
	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
		locationResolved = true
		
		CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: {(placemarks, error)->Void in
			if (error != nil) {
				println("Reverse geocoder failed with error: " + error.localizedDescription)
			}
			
			else if placemarks.count > 0 {
				self.lastPlacemark = placemarks[0] as! CLPlacemark
			}
			
			else {
				println("no placemark returned from geocoder")
			}
			
			NSNotificationCenter.defaultCenter().postNotificationName(kLocationHelperNotification, object:nil)
		})
	}
	
	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
		println("Location resolution failed")
		NSNotificationCenter.defaultCenter().postNotificationName(kLocationHelperNotification, object:nil)
	}
	
	func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		println("Location authorization changed to: \(status.rawValue)")
		authorizationStatus = status
		accessAuthorized = status == CLAuthorizationStatus.AuthorizedWhenInUse || status == CLAuthorizationStatus.AuthorizedAlways
		
		NSNotificationCenter.defaultCenter().postNotificationName(kLocationHelperNotification, object:nil)
	}
}
