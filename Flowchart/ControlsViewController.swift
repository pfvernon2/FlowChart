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
	
	@IBOutlet var flow: UIPickerView!
	@IBOutlet var flowSubmit: UIButton!
	@IBOutlet var flowSubmitStatus: UIActivityIndicatorView!

	@IBOutlet var puffs: UILabel!
	@IBOutlet var puffsSubmit: UIButton!
	@IBOutlet var puffsSubmitStatus: UIActivityIndicatorView!
	
	@IBOutlet var puffStepper: UIStepper!
	@IBOutlet var location: UIButton!
	
	var maxPeakFlow : Int = 0
	var minPeakFlow : Int = 0
	var avgPeakFlow : Int = 0

	//MARK: Actions
	@IBAction func puffAction(sender: UIStepper) {
		puffs.text = String(Int(puffStepper.value))
	}
	
	@IBAction func submitPEFRAction(sender: AnyObject) {
		self.flowSubmit.hidden = true;
		self.flowSubmitStatus.startAnimating();
		
		let flowRate = (flow.selectedRowInComponent(0)+1) * 10
		
		var location:CLLocation! = nil;
		if LocationHelper.sharedInstance.locationManager != nil {
			location = LocationHelper.sharedInstance.locationManager.location
		}
		
		HealthKitHelper.sharedInstance.writePeakFlowSample(flowRate, date:datestamp, location:location) { (success, error) -> () in
			
			if !success {
				var alertView = UIAlertView()
				alertView.title = NSLocalizedString("Peak Flow Update Failed", comment: "Peak Flow Update Failed - title")
				alertView.message = NSLocalizedString("Unable to access your HealthKit information. Please confirm this app is configured access your HealthKit data in Settings->Privacy->Health.", comment: "Peak Flow Update Failed - message")
				alertView.addButtonWithTitle("Dismiss")
				alertView.show()
			}
			
			self.delay(1.0, closure: { () -> () in
				self.flowSubmitStatus.stopAnimating();
				self.flowSubmit.hidden = false;
				self.updateDisplay()
			})
		}
	}
	
	@IBAction func submitInhalerAction(sender: AnyObject) {
		self.puffsSubmit.hidden = true;
		self.puffsSubmitStatus.startAnimating();

		let puffs = Int(puffStepper.value)
		
		var location:CLLocation! = nil;
		if LocationHelper.sharedInstance.locationManager != nil {
			location = LocationHelper.sharedInstance.locationManager.location
		}

		HealthKitHelper.sharedInstance.writeInhalerUsage(puffs, date:datestamp, location:location) { (success, error) -> () in
			
			if !success {
				var alertView = UIAlertView()
				alertView.title = NSLocalizedString("Inhaler Usage Failed", comment: "Inhaler Usage Failed - title")
				alertView.message = NSLocalizedString("Unable to access your HealthKit information. Please confirm this app is configured access your HealthKit data in Settings->Privacy->Health.", comment: "Inhaler Usage Failed - message")
				alertView.addButtonWithTitle("Dismiss")
				alertView.show()
			}
			
			self.delay(1.0, closure: { () -> () in
				self.puffsSubmitStatus.stopAnimating();
				self.puffsSubmit.hidden = false;
				self.updateDisplay()
			})
		}
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
		self.updateDisplay()
	}
	
	override func viewDidDisappear(animated: Bool) {
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func updateDisplay() {
		self.updateLocationButtonIcon()
		
		datestamp = NSDate()
		let format : NSDateFormatter = NSDateFormatter()
		format.dateStyle = .MediumStyle
		format.timeStyle = .ShortStyle
		
		//Get personal best
		HealthKitHelper.sharedInstance.getMaxPeakFlowSample({ (peakFlow, error) -> () in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.maxPeakFlow = (Int(peakFlow)/10) * 10
				self.flow.setNeedsDisplay()
			})
		})

		//Get personal worst
		HealthKitHelper.sharedInstance.getMinPeakFlowSample({ (peakFlow, error) -> () in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.minPeakFlow = (Int(peakFlow)/10) * 10
				self.flow.setNeedsDisplay()
			})
		})
		
		//select row representing moving average
		HealthKitHelper.sharedInstance.getPeakFlowAverage({ (peakFlow, error) -> () in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				//round down to nearest value in picker
				self.avgPeakFlow = (Int(peakFlow)/10) * 10
				self.flow.selectRow((self.avgPeakFlow/10)-1, inComponent: 0, animated:true)
			})
		})
		
		puffStepper.value = 0.0
		puffs.text = String(Int(puffStepper.value))
		
		HealthKitHelper.sharedInstance.connect()
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
	
	func delay(delay:Double, closure:()->()) {
		dispatch_after(
			dispatch_time(
				DISPATCH_TIME_NOW,
				Int64(delay * Double(NSEC_PER_SEC))
			),
			dispatch_get_main_queue(), closure)
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
	
//	func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
//		return 36.0
//	}
	
	//http://www.hopkinsmedicine.org/healthlibrary/test_procedures/pulmonary/peak_flow_measurement_92,P07755/
	func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
		
		let value:Int = (row+1) * 10
		
		var result:UIView! = nil
		if view != nil {
			result = view
		}
		else {
			var view:UIView = UIView(frame: CGRectMake(0, 0, pickerView.frame.size.width, 100))
			
			var label:UILabel = UILabel(frame: CGRectMake(0, 0, pickerView.frame.size.width, 100))
			label.textAlignment = .Center
			label.font = UIFont.systemFontOfSize(36.0)
			label.text = String(value)
			
			view.addSubview(label)
			
			if maxPeakFlow == 0 {
				label.textColor = UIColor.blackColor()
			}
			else if Double(value) >= (Double(maxPeakFlow) * 0.8) {
				label.textColor = UIColor.greenColor()
			}
			else if Double(value) >= (Double(maxPeakFlow) * 0.5) {
				label.textColor = UIColor.yellowColor()
			}
			else {
				label.textColor = UIColor.redColor()
			}
			
			//Display min/max limits
			if Double(value) == Double(self.avgPeakFlow) {
				var tag:UILabel = UILabel(frame: CGRectMake(10, 0, pickerView.frame.size.width/4.0, 100))
				tag.textAlignment = .Left
				tag.font = UIFont.systemFontOfSize(18.0)
				tag.text = NSLocalizedString("Average", comment: "Flow rate display: Average")
				tag.textColor = UIColor.lightGrayColor()
				view.addSubview(tag)
			}
			else if Double(value) == Double(self.maxPeakFlow) {
				var tag:UILabel = UILabel(frame: CGRectMake(10, 0, pickerView.frame.size.width/4.0, 100))
				tag.textAlignment = .Left
				tag.font = UIFont.systemFontOfSize(18.0)
				tag.text = NSLocalizedString("Best", comment: "Flow rate display: Best")
				tag.textColor = UIColor.lightGrayColor()
				view.addSubview(tag)
			}
			else if Double(value) == Double(self.minPeakFlow) {
				var tag:UILabel = UILabel(frame: CGRectMake(10, 0, pickerView.frame.size.width/4.0, 100))
				tag.textAlignment = .Left
				tag.font = UIFont.systemFontOfSize(18.0)
				tag.text = NSLocalizedString("Worst", comment: "Flow rate display: Worst")
				tag.textColor = UIColor.lightGrayColor()
				view.addSubview(tag)
			}

			result = view
		}
		
		return result
	}
}

