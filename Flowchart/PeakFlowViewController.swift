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
    
	@IBAction func submitPEFRAction(_ sender: AnyObject) {
		self.flowSubmit.isHidden = true;
		self.flowSubmitStatus.startAnimating();
		
		let flowRate = (flowPicker.selectedRow(inComponent: 0)+1) * 10
		
		var location:CLLocation! = nil;
		if LocationHelper.sharedInstance.locationManager != nil {
			location = LocationHelper.sharedInstance.locationManager.location
		}
		
		HealthKitHelper.sharedInstance.writePeakFlowSample(Double(flowRate), date:Date(), location:location) { (success, error) -> () in
			
			if !success {
                let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Peak Flow Update Failed", comment: "Peak Flow Update Failed - title"),
                    message:  NSLocalizedString("Unable to access your HealthKit information. Please confirm this app is configured access your HealthKit data in Settings->Privacy->Health.", comment: "Peak Flow Update Failed - message"),
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
			}
			
			self.delay(1.0, closure: { () -> () in
				self.flowSubmitStatus.stopAnimating();
				self.flowSubmit.isHidden = false;
				self.updateDisplay()
			})
		}
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
		
		//Get peak flow personal best
		uiUpdateGroup.enter();
		HealthKitHelper.sharedInstance.getMaxPeakFlowSample({ (peakFlow, error) -> () in
			self.maxPeakFlow = peakFlow
			uiUpdateGroup.leave();
		})
		
		//Get peak flow personal worst
		uiUpdateGroup.enter();
		HealthKitHelper.sharedInstance.getMinPeakFlowSample({ (peakFlow, error) -> () in
			self.minPeakFlow = peakFlow
			uiUpdateGroup.leave();
		})
		
		//get peak flow average
		uiUpdateGroup.enter();
		HealthKitHelper.sharedInstance.getPeakFlowAverage({ (peakFlow, error) -> () in
			self.avgPeakFlow = peakFlow
			uiUpdateGroup.leave();
		})
		
		uiUpdateGroup.notify(queue: DispatchQueue.main, execute: {
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

	func delay(_ delay:Double, closure:@escaping ()->()) {
		DispatchQueue.main.asyncAfter(
			deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
	}

	//MARK: Picker datasource
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return 800/10
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return String((row+1) * 10)
	}
	
	func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
		
		let value:Int = (row+1) * 10
		
		var result:UIView! = nil
		if view != nil {
			result = view
		}
		else {
			let view:UIView = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.size.width, height: 100))
			view.translatesAutoresizingMaskIntoConstraints = false
			
			//Value label
			let valueLabel:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: pickerView.frame.size.width, height: 100))
			valueLabel.textAlignment = .center
			valueLabel.font = UIFont.boldSystemFont(ofSize: 36.0)
			valueLabel.text = String(value) //String(format: "%d L/min", value)
			view.addSubview(valueLabel)
			
			//Notation label
			let notationLabel:UILabel = UILabel(frame: CGRect(x: 10, y: 0, width: pickerView.frame.size.width/4.0, height: 100))
			notationLabel.textAlignment = .left
			notationLabel.font = UIFont.systemFont(ofSize: 18.0)
			notationLabel.textColor = UIColor.white
			view.addSubview(notationLabel)
			
			//Color coding per standard:
			//http://www.hopkinsmedicine.org/healthlibrary/test_procedures/pulmonary/peak_flow_measurement_92,P07755/
			if maxPeakFlow == 0 {
				valueLabel.textColor = UIColor.white
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
