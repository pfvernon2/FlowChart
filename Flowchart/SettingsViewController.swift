//
//  SettingsViewController.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/18/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIDocumentPickerDelegate {
	
	@IBOutlet var recordLocationSwitch: UISwitch!
	@IBOutlet var locationWarningImageView: UIImageView!
	
	@IBAction func doneAction(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func warningTapAction(sender: AnyObject) {
		var alertView = UIAlertView()
		alertView.title = NSLocalizedString("Location Service Disabled", comment: "Location Service Disabled - title")
		let locationDisplay:String = NSLocalizedString("You have opted to record your location however location services are not enabled for this application. You can correct this in your iPhone Settings under Privacy/Location Services.", comment: "Location Service Disabled - message")
		alertView.message = locationDisplay
		alertView.addButtonWithTitle("Dismiss")
		alertView.show()
	}
	
	@IBAction func importAction(sender: AnyObject) {
		let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text"], inMode: .Import)
		documentPicker.delegate = self;
		documentPicker.modalPresentationStyle = .FullScreen
		self.presentViewController(documentPicker, animated: true) { () -> Void in
		}
	}
	
	@IBAction func locationSettingAction(sender: AnyObject) {
		LocationHelper.sharedInstance.setUserLocationTrackingUserPref(recordLocationSwitch.on)
		self.updateDisplay()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		NSNotificationCenter.defaultCenter().addObserverForName(kLocationHelperNotification, object:nil, queue:nil) { _ in
			self.updateDisplay()
		}
    }
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func viewWillAppear(animated: Bool) {
		self.updateDisplay()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	func updateDisplay() {
		let userPref = LocationHelper.sharedInstance.trackLocationPref
		let accessAuthorized = LocationHelper.sharedInstance.accessAuthorized

		recordLocationSwitch.on = userPref
		
		if userPref && !accessAuthorized {
			locationWarningImageView.hidden = false;
		} else {
			locationWarningImageView.hidden = true;
		}
	}
	
	//MARK: - DocumentPicker
	func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL)
	{
		var csvData:NSData = NSData(contentsOfURL: url)!
		var dataString:String = NSString(data: csvData, encoding:NSASCIIStringEncoding)!
		
		let count = CoreDataHelper.sharedInstance.importData(dataString)
		if count <= 0 {
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Import Failed", comment: "Import Failed - title")
			let locationDisplay:String = NSLocalizedString("The import of your data has failed. No data was imported. Please check your data format and try again, or don't, I'm not your mother.", comment: "Import Failed - message")
			alertView.message = locationDisplay
			alertView.addButtonWithTitle("Dismiss")
			alertView.show()
		} else {
			var alertView = UIAlertView()
			alertView.title = NSLocalizedString("Success!", comment: "Import success - title")
			var locationDisplay:String = NSLocalizedString("We imported %lu records.", comment: "Import success - message")
			locationDisplay = String(format: locationDisplay, count)
			alertView.message = locationDisplay
			alertView.addButtonWithTitle("Yeah!")
			alertView.show()
		}
	}
	
	func documentPickerWasCancelled(controller: UIDocumentPickerViewController)
	{
		
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
