//
//  InhalerViewController.swift
//  Flowchart
//
//  Created by Frank Vernon on 11/5/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit
import CoreLocation

class InhalerViewController: UIViewController {

	@IBOutlet var inhalerValueLabel: UILabel!
	@IBOutlet var inhalerSubmit: UIButton!
	@IBOutlet var inhalerSubmitStatus: UIActivityIndicatorView!
	@IBOutlet var inhalerStepper: UIStepper!
	var inhalerAverageLabel: UILabel!

	var avgInhaler : Double = 0.0

	@IBAction func inhalerAction(sender: UIStepper) {
		inhalerValueLabel.text = String(Int(inhalerStepper.value))
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
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func viewDidAppear(animated: Bool) {
		self.updateDisplay()
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
		
		//Display inhaler average
		dispatch_group_enter(uiUpdateGroup);
		HealthKitHelper.sharedInstance.getInhalerAverage({ (inhaler, error) -> () in
			self.avgInhaler = inhaler
			dispatch_group_leave(uiUpdateGroup);
		})
		
		dispatch_group_notify(uiUpdateGroup, dispatch_get_main_queue(), {
			//display inhaler usage average
			let peakLabel:String = NSLocalizedString("Daily Average", comment: "Inhaler Daily Average Label")
			self.inhalerAverageLabel.text = String(format: "%@: %0.2f", peakLabel, self.avgInhaler)

			//update puffer stepper display
			self.inhalerStepper.value = 0.0
			self.inhalerValueLabel.text = String(Int(self.inhalerStepper.value))
		})
	}

	func delay(delay:Double, closure:()->()) {
		dispatch_after(
			dispatch_time(
				DISPATCH_TIME_NOW,
				Int64(delay * Double(NSEC_PER_SEC))
			),
			dispatch_get_main_queue(), closure)
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
