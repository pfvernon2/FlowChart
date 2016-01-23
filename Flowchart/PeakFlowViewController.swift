//
//  PeakFlowViewController.swift
//  Flowchart
//
//  Created by Frank Vernon on 11/5/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit
import CoreLocation

class PeakFlowViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

	//MARK: Controls
	@IBOutlet var flowPicker: UIPickerView!
	@IBOutlet var flowSubmit: UIButton!
	@IBOutlet var flowSubmitStatus: UIActivityIndicatorView!
	var flowAverageLabel: UILabel!

	//MARK: Member Variables
	var maxPeakFlow : Double = 0.0
	var minPeakFlow : Double = 0.0
	var avgPeakFlow : Double = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Peak Flow Update Failed", comment: "Peak Flow Update Failed - title"),
                    message:  NSLocalizedString("Unable to access your HealthKit information. Please confirm this app is configured access your HealthKit data in Settings->Privacy->Health.", comment: "Peak Flow Update Failed - message"),
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
			}
			
			self.delay(1.0, closure: { () -> () in
				self.flowSubmitStatus.stopAnimating();
				self.flowSubmit.hidden = false;
				self.updateDisplay()
			})
		}
	}

	func updateDisplay() {
		//create group so we can join on results and update the display atomically
		let uiUpdateGroup:dispatch_group_t = dispatch_group_create();
		
		dispatch_group_enter(uiUpdateGroup);
		if !HealthKitHelper.sharedInstance.connect ({ (success, error) -> () in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				dispatch_group_leave(uiUpdateGroup);
				
				if (!success) {
                    let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Sorry", comment: "HealthKit access error - title"),
                        message:  NSLocalizedString("We were unable to access your data in HealthKit.\n\nYou can correct this in your iPhone Settings under Privacy/Health", comment: "HealthKit access error - message"),
                        preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
				}
			})
		})
		{
			dispatch_group_leave(uiUpdateGroup);
			
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Sorry", comment: "HealthKit not available - title"),
                message:  NSLocalizedString("HealthKit is not available on this device.", comment: "HealthKit not available - message"),
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
			
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
		
		dispatch_group_notify(uiUpdateGroup, dispatch_get_main_queue(), {
			//display peak flow average
			let peakLabel:String = NSLocalizedString("Daily Average", comment: "Peak Flow Daily Average Label")
			self.flowAverageLabel.text = String(format: "%@: %0.2f", peakLabel, self.avgPeakFlow)
						
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
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return String((row+1) * 10)
	}
	
	func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
		
		let value:Int = (row+1) * 10
		
		var result:UIView! = nil
		if view != nil {
			result = view
		}
		else {
			let view:UIView = UIView(frame: CGRectMake(0, 0, pickerView.frame.size.width, 100))
			view.translatesAutoresizingMaskIntoConstraints = false
			
			//Value label
			let valueLabel:UILabel = UILabel(frame: CGRectMake(0, 0, pickerView.frame.size.width, 100))
			valueLabel.textAlignment = .Center
			valueLabel.font = UIFont.boldSystemFontOfSize(36.0)
			valueLabel.text = String(value) //String(format: "%d L/min", value)
			view.addSubview(valueLabel)
			
			//Notation label
			let notationLabel:UILabel = UILabel(frame: CGRectMake(10, 0, pickerView.frame.size.width/4.0, 100))
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
