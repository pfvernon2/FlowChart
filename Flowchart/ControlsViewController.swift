//
//  ControlsViewController.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/17/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit
import CoreLocation

let kMinDistanceUpdateMeters:Double = 1000

class ControlsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
	
	var datestamp: NSDate!
	
	@IBOutlet var date: UILabel!
	@IBOutlet var flow: UIPickerView!
	@IBOutlet var puffs: UILabel!
	@IBOutlet var puffStepper: UIStepper!
	@IBOutlet var location: UIButton!
	
	//MARK: Actions
	@IBAction func puffAction(sender: UIStepper) {
		puffs.text = String(Int(puffStepper.value))
	}
	
	@IBAction func submitAction(sender: AnyObject) {
		let flowRate = (flow.selectedRowInComponent(0)+1) * 10
		let puffs = Int(puffStepper.value)
		
		var location:CLLocation! = nil;
		if LocationHelper.sharedInstance.locationManager != nil {
			location = LocationHelper.sharedInstance.locationManager.location
		}
		
		CoreDataHelper.sharedInstance.saveCurrentRecord(datestamp, location:location, flowRate:flowRate, puffs:puffs)
		HealthKitHelper.sharedInstance.writePeakFlowValue(flowRate, date:datestamp)
		HealthKitHelper.sharedInstance.writeInhalerUsage(puffs, date:datestamp)
	}
	
	@IBAction func locationAction(sender: AnyObject) {
		if (!LocationHelper.sharedInstance.trackLocationPref) {
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Your location is unknown", comment: "Your location unknown - title")
			alertView.message = NSLocalizedString("Enable location tracking in Settings if you wish to record your location with your HealthKit data.", comment: "Your location - enable in prefs")
			alertView.addButtonWithTitle("Dismiss")
			alertView.show()
		}
			
		else if (!LocationHelper.sharedInstance.accessAuthorized) {
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Your location is unavailable", comment: "Your location unavailable - title")
			alertView.message = NSLocalizedString("You have opted to have this app record your location but you have not authorized access to your location information. You can disable this option in settings or enable access to your location in your iPhone Settings under Privacy/Location Services.", comment: "Your location - enable in settings")
			alertView.addButtonWithTitle("Dismiss")
			alertView.show()
		}
			
		else if LocationHelper.sharedInstance.lastPlacemark != nil {
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Your location", comment: "Your location - title")
			let locationDisplay:String = LocationHelper.sharedInstance.displayPlacemark()
			alertView.message = locationDisplay
			alertView.addButtonWithTitle("Dismiss")
			alertView.show()
		}
			
		else if LocationHelper.sharedInstance.locationResolved {
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Your location", comment: "Your location - title")
			let locationDisplay:String = LocationHelper.sharedInstance.displayLocation()
			alertView.message = locationDisplay
			alertView.addButtonWithTitle("Dismiss")
			alertView.show()
		}
		
		else {
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Your location cannot be determined", comment: "Your location not determined - title")
			let locationDisplay:String = LocationHelper.sharedInstance.displayLocation()
			alertView.message = locationDisplay
			alertView.addButtonWithTitle("Dismiss")
			alertView.show()
		}
	}
	
	//MARK: View lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserverForName(kLocationHelperNotification, object:nil, queue:nil) { _ in
			self.updateLocationButtonIcon()
		}
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	override func viewDidAppear(animated: Bool) {
		self.updateLocationButtonIcon()
		
		datestamp = NSDate()
		let format : NSDateFormatter = NSDateFormatter()
		format.dateStyle = .MediumStyle
		format.timeStyle = .ShortStyle
		date.text = format.stringFromDate(datestamp)

		//select row representing moving average
		let averageFlow = CoreDataHelper.sharedInstance.peakFlowMovingAverage()
		flow.selectRow((averageFlow/10)-1, inComponent: 0, animated:true)
		
		puffs.text = String(Int(puffStepper.value))
		
		HealthKitHelper.sharedInstance.connect()
	}
	
	override func viewDidDisappear(animated: Bool) {
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func updateLocationButtonIcon() {
		let userPref:Bool = LocationHelper.sharedInstance.trackLocationPref
		let accessAuth:Bool = LocationHelper.sharedInstance.accessAuthorized
		let locationResolved:Bool = LocationHelper.sharedInstance.locationResolved

		if !userPref {
			location.hidden = true;
		}
		
		else if userPref && !accessAuth {
			location.hidden = false;
			var image:UIImage? = UIImage(named:"warning")
			location.setImage(image, forState:.Normal)
		}
		
		else if userPref && !locationResolved {
			location.hidden = false;
			var image:UIImage? = UIImage(named:"location empty")
			location.setImage(image, forState:.Normal)
		}
			
		else {
			location.hidden = false;
			var image:UIImage? = UIImage(named:"location")
			location.setImage(image, forState:.Normal)
		}
	}
	
	//MARK: Picker lifecycle
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return (800/100) * 10
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
		return String((row+1) * 10)
	}
	
}

