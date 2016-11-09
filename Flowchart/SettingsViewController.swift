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
	var saveURL:URL? = nil
	var saveCount:Int = 0

	//MARK: Actions
	@IBAction func doneAction(_ sender: AnyObject) {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func warningTapAction(_ sender: AnyObject) {
        let locationDisplay:String = NSLocalizedString("You have opted to record your location however location services are not enabled for this application. You can correct this in your iPhone Settings under Privacy/Location Services.", comment: "Location Service Disabled - message")
        let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Location Service Disabled", comment: "Location Service Disabled - title"),
            message:  locationDisplay,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
	}
	
	@IBAction func importAction(_ sender: AnyObject) {
		let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text"], in: .import)
		documentPicker.delegate = self;
		documentPicker.modalPresentationStyle = .fullScreen
		self.inOpen = true
		self.present(documentPicker, animated: true) { () -> Void in
		}
	}
	
	@IBAction func exportAction(_ sender: AnyObject) {
		self.exportButton.isHidden = true
		self.exportStatus.startAnimating()

		HealthKitHelper.sharedInstance.exportSamples { (peakFlow, inhaler, error) -> () in
			DispatchQueue.main.async(execute: { () -> Void in
				self.exportStatus.stopAnimating()
				self.exportButton.isHidden = false
			})
			
			if let _ = error {
                let locationDisplay:String = NSLocalizedString("We were unable to access your HealthKit data. Please ensure that you have granted this app access to your HealthKit data in Settings->Privacy->Health.", comment: "Export Failed - message")
                let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Export Failed", comment: "Export Failed - title"),
                    message:  locationDisplay,
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
			}
			else {
				//create temp file with well known name
				let dir:NSString = NSTemporaryDirectory() as NSString
				let appName:AnyObject? = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as AnyObject?
				let filename:String = String(format: "%@.csv", appName as! String)
				let path:String = dir.appendingPathComponent(filename)
				let url:URL = URL(fileURLWithPath: path)
				
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
				let documentPicker = UIDocumentPickerViewController(url: url, in: .exportToService)
				documentPicker.delegate = self;
				documentPicker.modalPresentationStyle = .fullScreen
				self.inSave = true
				self.saveURL = url
				self.present(documentPicker, animated: true) { () -> Void in
				}
			}
		}
	}
	
	@IBAction func locationSettingAction(_ sender: AnyObject) {
		LocationHelper.sharedInstance.setUserLocationTrackingUserPref(recordLocationSwitch.isOn)
		self.updateDisplay()
	}
	
	//MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

		self.versionInfoLabel.text = AppDelegate().appNameAndVersionNumberDisplayString()
		
		NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kLocationHelperNotification), object:nil, queue:nil) { _ in
			self.updateDisplay()
		}
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	override func viewWillAppear(_ animated: Bool) {
		self.updateDisplay()
	}
	
	override func viewDidAppear(_ animated: Bool) {
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	func updateDisplay() {
		let userPref = LocationHelper.sharedInstance.trackLocationPref
		let accessAuthorized = LocationHelper.sharedInstance.accessAuthorized

		recordLocationSwitch.isOn = userPref
		
		if userPref && !accessAuthorized {
			locationWarningImageView.isHidden = false;
		} else {
			locationWarningImageView.isHidden = true;
		}
	}
	
	//MARK: - DocumentPicker
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL)
	{
		//Do open operation
		if self.inOpen {
			self.inOpen = false
			self.importButton.isHidden = true
			self.importStatus.startAnimating()
			
			DispatchQueue.global().async(execute: { () -> Void in
				let table = CSVHelper().read(contentsOfURL: url)
				HealthKitHelper.sharedInstance.importSamples(table, completion: { (count) -> () in
					DispatchQueue.main.async(execute: { () -> Void in
						if count <= 0 {
                            let locationDisplay:String = NSLocalizedString("The import of your data has failed. No data was imported. Please check your data format and try again, or don't, I'm not your mother.", comment: "Import Failed - message")
                            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Import Failed", comment: "Import Failed - title"),
                                message:  locationDisplay,
                                preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
						} else {
                            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Success!", comment: "Import success - title"),
                                message:  nil,
                                preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Yeah!", comment:""), style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
						}
						self.importButton.isHidden = false
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
					try FileManager.default.removeItem(atPath: tempURL.path)
				} catch _ {
				}
			}
			
			//indicate success
            let locationDisplay:String = NSLocalizedString("We exported %lu records!", comment: "Export success - message")
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Success!", comment: "Import success - title"),
                message:  locationDisplay,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Yeah!", comment:""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
		}
	}
	
	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController)
	{
		self.inOpen = false
		self.inSave = false
		
		//cleanup temp file
		if let tempURL = self.saveURL {
			do {
				try FileManager.default.removeItem(atPath: tempURL.path)
			} catch _ {
			}
		}
	}
}
