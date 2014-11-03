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
	
	//MARK: Controls
	@IBOutlet var flowPicker: UIPickerView!
	@IBOutlet var flowSubmit: UIButton!
	@IBOutlet var flowSubmitStatus: UIActivityIndicatorView!
	@IBOutlet var flowAverageLabel: UILabel!

	@IBOutlet var inhalerValueLabel: UILabel!
	@IBOutlet var inhalerAverageLabel: UILabel!
	@IBOutlet var inhalerSubmit: UIButton!
	@IBOutlet var inhalerSubmitStatus: UIActivityIndicatorView!
	@IBOutlet var inhalerStepper: UIStepper!
	
	@IBOutlet var location: UIButton!
	
	//MARK: Member Variables
	var maxPeakFlow : Double = 0.0
	var minPeakFlow : Double = 0.0
	var avgPeakFlow : Double = 0.0
	var avgInhaler : Double = 0.0

	//MARK: Actions
	@IBAction func inhalerAction(sender: UIStepper) {
		inhalerValueLabel.text = String(Int(inhalerStepper.value))
	}
	
	@IBAction func submitPEFRAction(sender: AnyObject) {
		self.flowSubmit.hidden = true;
		self.flowSubmitStatus.startAnimating();
		
		let flowRate = (flowPicker.selectedRowInComponent(0)+1) * 10
		
		var location:CLLocation! = nil;
		if LocationHelper.sharedInstance.locationManager != nil {
			location = LocationHelper.sharedInstance.locationManager.location
		}
		
		HealthKitHelper.sharedInstance.writePeakFlowSample(Double(flowRate), date:NSDate(), location:location) { (success, error) -> () in
			
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
		self.inhalerSubmit.hidden = true;
		self.inhalerSubmitStatus.startAnimating();

		let inhaler = Int(inhalerStepper.value)
		
		var location:CLLocation! = nil;
		if LocationHelper.sharedInstance.locationManager != nil {
			location = LocationHelper.sharedInstance.locationManager.location
		}

		HealthKitHelper.sharedInstance.writeInhalerUsage(Double(inhaler), date:NSDate(), location:location) { (success, error) -> () in
			
			if !success {
				var alertView = UIAlertView()
				alertView.title = NSLocalizedString("Inhaler Usage Failed", comment: "Inhaler Usage Failed - title")
				alertView.message = NSLocalizedString("Unable to access your HealthKit information. Please confirm this app is configured access your HealthKit data in Settings->Privacy->Health.", comment: "Inhaler Usage Failed - message")
				alertView.addButtonWithTitle("Dismiss")
				alertView.show()
			}
			
			self.delay(1.0, closure: { () -> () in
				self.inhalerSubmitStatus.stopAnimating();
				self.inhalerSubmit.hidden = false;
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
		//create group so we can join on results and update the display atomically
		let uiUpdateGroup:dispatch_group_t = dispatch_group_create();
		
		dispatch_group_enter(uiUpdateGroup);
		if !HealthKitHelper.sharedInstance.connect ({ (success, error) -> () in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				dispatch_group_leave(uiUpdateGroup);
				
				if (!success) {
					var alertView = UIAlertView()
					alertView.title = NSLocalizedString("Sorry", comment: "HealthKit access error - title")
					alertView.message = NSLocalizedString("We were unable to access your data in HealthKit.\n\nYou can correct this in your iPhone Settings under Privacy/Health", comment: "HealthKit access error - message")
					alertView.addButtonWithTitle("Dismiss")
					alertView.show()
				}
			})
		})
		{
			dispatch_group_leave(uiUpdateGroup);
			
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Sorry", comment: "HealthKit not available - title")
			alertView.message = NSLocalizedString("HealthKit is not available on this device.", comment: "HealthKit not available - message")
			alertView.addButtonWithTitle("Dismiss")
			alertView.show()
			
			return;
		}
		
		//Get peak flow personal best
		dispatch_group_enter(uiUpdateGroup);
		HealthKitHelper.sharedInstance.getMaxPeakFlowSample({ (peakFlow, error) -> () in
			self.maxPeakFlow = peakFlow
			dispatch_group_leave(uiUpdateGroup);
		})
		
		//Get peak flow personal worst
		dispatch_group_enter(uiUpdateGroup);
		HealthKitHelper.sharedInstance.getMinPeakFlowSample({ (peakFlow, error) -> () in
			self.minPeakFlow = peakFlow
			dispatch_group_leave(uiUpdateGroup);
		})
		
		//get peak flow average
		dispatch_group_enter(uiUpdateGroup);
		HealthKitHelper.sharedInstance.getPeakFlowAverage({ (peakFlow, error) -> () in
			self.avgPeakFlow = peakFlow
			dispatch_group_leave(uiUpdateGroup);
		})
		
		//Display inhaler average
		dispatch_group_enter(uiUpdateGroup);
		HealthKitHelper.sharedInstance.getInhalerAverage({ (inhaler, error) -> () in
			self.avgInhaler = inhaler
			dispatch_group_leave(uiUpdateGroup);
		})
		
		dispatch_group_notify(uiUpdateGroup, dispatch_get_main_queue(), {
			//update location status
			self.updateLocationButtonIcon()
			
			//update puffer stepper display
			self.inhalerStepper.value = 0.0
			self.inhalerValueLabel.text = String(Int(self.inhalerStepper.value))
			
			//display peak flow average
			let peakLabel:String = NSLocalizedString("Daily Average: ", comment: "Peak Flow Daily Average Label")
			self.flowAverageLabel.text = String(format: "%@: %0.2f", peakLabel, self.avgPeakFlow)
			
			//display inhaler average
			let inhalerLabel:String = NSLocalizedString("Daily Average: ", comment: "Inhaler Daily Average Label")
			self.inhalerAverageLabel.text = String(format: "%@: %0.2f", inhalerLabel, self.avgInhaler)
			
			//udpate picker display
			self.flowPicker.reloadAllComponents()
			self.flowPicker.setNeedsDisplay()
			if self.avgPeakFlow > 0 {
				self.flowPicker.selectRow(Int((self.avgPeakFlow/10.0))-1, inComponent: 0, animated:true)
			} else {
				self.flowPicker.selectRow((450/10)-1, inComponent: 0, animated:true)
			}
		})
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

	//MARK: Picker datasource
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return 800/10
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
		return String((row+1) * 10)
	}
	
	func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
		
		let value:Int = (row+1) * 10
		
		var result:UIView! = nil
		if view != nil {
			result = view
		}
		else {
			var view:UIView = UIView(frame: CGRectMake(0, 0, pickerView.frame.size.width, 100))
			view.setTranslatesAutoresizingMaskIntoConstraints(false)
			
			//Value label
			var valueLabel:UILabel = UILabel(frame: CGRectMake(0, 0, pickerView.frame.size.width, 100))
			valueLabel.textAlignment = .Center
			valueLabel.font = UIFont.boldSystemFontOfSize(36.0)
			valueLabel.text = String(value) //String(format: "%d L/min", value)
			view.addSubview(valueLabel)
			
			//Notation label
			var notationLabel:UILabel = UILabel(frame: CGRectMake(10, 0, pickerView.frame.size.width/4.0, 100))
			notationLabel.textAlignment = .Left
			notationLabel.font = UIFont.systemFontOfSize(18.0)
			notationLabel.textColor = UIColor.whiteColor()
			view.addSubview(notationLabel)
			
			//Color coding per standard:
			//http://www.hopkinsmedicine.org/healthlibrary/test_procedures/pulmonary/peak_flow_measurement_92,P07755/
			if maxPeakFlow == 0 {
				valueLabel.textColor = UIColor.whiteColor()
			}
			else if Double(value) >= (maxPeakFlow * 0.8) {
				valueLabel.textColor = UIColor(red: 2.0/255.0, green: 183.0/255.0, blue: 35.0/255.0, alpha: 1.0)
			}
			else if Double(value) >= (maxPeakFlow * 0.5) {
				valueLabel.textColor = UIColor(red: 235.0/255.0, green: 240.0/255.0, blue: 5.0/255.0, alpha: 1.0)
			}
			else {
				valueLabel.textColor = UIColor(red: 220.0/255.0, green: 26.0/255.0, blue: 100.0/255.0, alpha: 1.0)
			}
			
			//Display min/max limits
			if value == Int(self.avgPeakFlow/10.0)*10 {
				notationLabel.text = NSLocalizedString("Average", comment: "Flow rate display: Average")
			}
			else if value ==  Int(self.maxPeakFlow/10.0)*10 {
				notationLabel.text = NSLocalizedString("Best", comment: "Flow rate display: Best")
			}
			else if value == Int(self.minPeakFlow/10.0)*10 {
				notationLabel.text = NSLocalizedString("Worst", comment: "Flow rate display: Worst")
			} else {
				notationLabel.text = ""
			}

			result = view
		}
		
		return result
	}
}

