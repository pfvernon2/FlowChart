//
//  SettingsViewController.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/18/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIDocumentPickerDelegate {
	
	//MARK: Controls
	@IBOutlet var recordLocationSwitch: UISwitch!
	@IBOutlet var locationWarningImageView: UIImageView!
	@IBOutlet var versionInfoLabel: UILabel!
	
	@IBOutlet var importButton: UIButton!
	@IBOutlet var importStatus: UIActivityIndicatorView!
	
	@IBOutlet var exportButton: UIButton!
	@IBOutlet var exportStatus: UIActivityIndicatorView!
	
	//MARK: Member Variables
	var inOpen:Bool = false
	var inSave:Bool = false
	var saveURL:NSURL? = nil
	var saveCount:Int = 0

	//MARK: Actions
	@IBAction func doneAction(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func warningTapAction(sender: AnyObject) {
        let locationDisplay:String = NSLocalizedString("You have opted to record your location however location services are not enabled for this application. You can correct this in your iPhone Settings under Privacy/Location Services.", comment: "Location Service Disabled - message")
        let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Location Service Disabled", comment: "Location Service Disabled - title"),
            message:  locationDisplay,
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
	}
	
	@IBAction func importAction(sender: AnyObject) {
		let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text"], inMode: .Import)
		documentPicker.delegate = self;
		documentPicker.modalPresentationStyle = .FullScreen
		self.inOpen = true
		self.presentViewController(documentPicker, animated: true) { () -> Void in
		}
	}
	
	@IBAction func exportAction(sender: AnyObject) {
		self.exportButton.hidden = true
		self.exportStatus.startAnimating()

		HealthKitHelper.sharedInstance.exportSamples { (peakFlow, inhaler, error) -> () in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.exportStatus.stopAnimating()
				self.exportButton.hidden = false
			})
			
			if let _ = error {
                let locationDisplay:String = NSLocalizedString("We were unable to access your HealthKit data. Please ensure that you have granted this app access to your HealthKit data in Settings->Privacy->Health.", comment: "Export Failed - message")
                let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Export Failed", comment: "Export Failed - title"),
                    message:  locationDisplay,
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
			}
			else {
				//create temp file with well known name
				let dir:NSString = NSTemporaryDirectory()
				let appName:AnyObject? = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName")
				let filename:String = String(format: "%@.csv", appName as! String)
				let path:String = dir.stringByAppendingPathComponent(filename)
				let url:NSURL = NSURL.fileURLWithPath(path)
				
				//combine data sets... use header from first available
				var data:[[String]] = [[String]]()
				if peakFlow.count > 1 {
					data = peakFlow
				}
				if inhaler.count > 1 && data.count > 1{
					data += inhaler[1...inhaler.count-1]
				} else {
					data = inhaler
				}
				
				CSVHelper().write(data, toFile: url)
				self.saveCount = data.count
				
				//move temp file to iCloud, or wherever
				let documentPicker = UIDocumentPickerViewController(URL: url, inMode: .ExportToService)
				documentPicker.delegate = self;
				documentPicker.modalPresentationStyle = .FullScreen
				self.inSave = true
				self.saveURL = url
				self.presentViewController(documentPicker, animated: true) { () -> Void in
				}
			}
		}
	}
	
	@IBAction func locationSettingAction(sender: AnyObject) {
		LocationHelper.sharedInstance.setUserLocationTrackingUserPref(recordLocationSwitch.on)
		self.updateDisplay()
	}
	
	//MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

		self.versionInfoLabel.text = AppDelegate().appNameAndVersionNumberDisplayString()
		
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
	
	override func viewDidAppear(animated: Bool) {
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
		//Do open operation
		if self.inOpen {
			self.inOpen = false
			self.importButton.hidden = true
			self.importStatus.startAnimating()
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
				let table = CSVHelper().read(contentsOfURL: url)
				HealthKitHelper.sharedInstance.importSamples(table, completion: { (count) -> () in
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						if count <= 0 {
                            let locationDisplay:String = NSLocalizedString("The import of your data has failed. No data was imported. Please check your data format and try again, or don't, I'm not your mother.", comment: "Import Failed - message")
                            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Import Failed", comment: "Import Failed - title"),
                                message:  locationDisplay,
                                preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .Default, handler: nil))
                            self.presentViewController(alert, animated: true, completion: nil)
						} else {
                            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Success!", comment: "Import success - title"),
                                message:  nil,
                                preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Yeah!", comment:""), style: .Default, handler: nil))
                            self.presentViewController(alert, animated: true, completion: nil)
						}
						self.importButton.hidden = false
						self.importStatus.stopAnimating()
					})
				})
			})
		}
		
		//Do save operation
		else if self.inSave {
			self.inSave = false
			
			//cleanup temp file
			if let tempURL = self.saveURL {
				do {
					try NSFileManager.defaultManager().removeItemAtPath(tempURL.path!)
				} catch _ {
				}
			}
			
			//indicate success
            let locationDisplay:String = NSLocalizedString("We exported %lu records!", comment: "Export success - message")
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Success!", comment: "Import success - title"),
                message:  locationDisplay,
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Yeah!", comment:""), style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
	func documentPickerWasCancelled(controller: UIDocumentPickerViewController)
	{
		self.inOpen = false
		self.inSave = false
		
		//cleanup temp file
		if let tempURL = self.saveURL {
			do {
				try NSFileManager.defaultManager().removeItemAtPath(tempURL.path!)
			} catch _ {
			}
		}
	}
}
