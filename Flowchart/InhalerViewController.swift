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

	@IBAction func inhalerAction(_ sender: UIStepper) {
		inhalerValueLabel.text = String(Int(inhalerStepper.value))
	}

	@IBAction func submitInhalerAction(_ sender: AnyObject) {
		self.inhalerSubmit.isHidden = true;
		self.inhalerSubmitStatus.startAnimating();
		
		let inhaler = Int(inhalerStepper.value)
		
		var location:CLLocation! = nil;
		if LocationHelper.sharedInstance.locationManager != nil {
			location = LocationHelper.sharedInstance.locationManager.location
		}
		
		HealthKitHelper.sharedInstance.writeInhalerUsage(Double(inhaler), date:Date(), location:location) { (success, error) -> () in
			
			if !success {
                let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Inhaler Usage Failed", comment: "Inhaler Usage Failed - title"),
                    message:  NSLocalizedString("Unable to access your HealthKit information. Please confirm this app is configured access your HealthKit data in Settings->Privacy->Health.", comment: "Inhaler Usage Failed - message"),
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
			}
			
			self.delay(1.0, closure: { () -> () in
				self.inhalerSubmitStatus.stopAnimating();
				self.inhalerSubmit.isHidden = false;
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
	
	override func viewDidAppear(_ animated: Bool) {
		self.updateDisplay()
	}

	func updateDisplay() {
		//create group so we can join on results and update the display atomically
		let uiUpdateGroup:DispatchGroup = DispatchGroup();
		
		uiUpdateGroup.enter();
		if !HealthKitHelper.sharedInstance.connect ({ (success, error) -> () in
			DispatchQueue.main.async(execute: { () -> Void in
				uiUpdateGroup.leave();
				
				if (!success) {
                    let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Sorry", comment: "HealthKit access error - title"),
                        message:  NSLocalizedString("We were unable to access your data in HealthKit.\n\nYou can correct this in your iPhone Settings under Privacy/Health", comment: "HealthKit access error - message"),
                        preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
				}
			})
		})
		{
			uiUpdateGroup.leave();
			
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Sorry", comment: "HealthKit not available - title"),
                message:  NSLocalizedString("HealthKit is not available on this device.", comment: "HealthKit not available - message"),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
			
			return;
		}
		
		//Display inhaler average
		uiUpdateGroup.enter();
		HealthKitHelper.sharedInstance.getInhalerAverage({ (inhaler, error) -> () in
			self.avgInhaler = inhaler
			uiUpdateGroup.leave();
		})
		
		uiUpdateGroup.notify(queue: DispatchQueue.main, execute: {
			//display inhaler usage average
			let peakLabel:String = NSLocalizedString("Daily Average", comment: "Inhaler Daily Average Label")
			self.inhalerAverageLabel.text = String(format: "%@: %0.2f", peakLabel, self.avgInhaler)

			//update puffer stepper display
			self.inhalerStepper.value = 0.0
			self.inhalerValueLabel.text = String(Int(self.inhalerStepper.value))
		})
	}

	func delay(_ delay:Double, closure:@escaping ()->()) {
		DispatchQueue.main.asyncAfter(
			deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
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
