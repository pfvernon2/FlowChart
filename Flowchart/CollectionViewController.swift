//
//  CollectionViewController.swift
//  Flowchart
//
//  Created by Frank Vernon on 11/4/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

let reuseIdentifier = "CollectionCell"

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

	//MARK: Controls
	var locationButton: UIButton!

	//MARK: Member variables
	var selectedSection: IndexPath = IndexPath(item: 0, section: 0)
	let sectionTitles = [
		NSLocalizedString("Peak Expiratory Flow", comment: "Peak Expiratory Flow -  section title"),
		NSLocalizedString("Inhaler Usage", comment: "Inhaler Usage -  section title")
	]
	
	//MARK: Actions
	func locationAction(_ sender: AnyObject) {
		if (!LocationHelper.sharedInstance.trackLocationPref) {
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Your location is unknown", comment: "Your location unknown - title"),
                message:  NSLocalizedString("Enable location tracking in Settings if you wish to record your location with your HealthKit data.", comment: "Your location - enable in prefs"),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
		}
			
		else if (!LocationHelper.sharedInstance.accessAuthorized) {
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Your location is unavailable", comment: "Your location unavailable - title"),
                message:  NSLocalizedString("You have opted to have this app record your location but you have not authorized access to your location information. You can disable this option in settings or enable access to your location in your iPhone Settings under Privacy/Location Services.", comment: "Your location - enable in settings"),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
		}
			
		else if LocationHelper.sharedInstance.lastPlacemark != nil {
            let locationDisplay:String = LocationHelper.sharedInstance.displayPlacemark()
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Your location", comment: "Your location - title"),
                message:  locationDisplay,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
		}
			
		else if LocationHelper.sharedInstance.locationResolved {
            let locationDisplay:String = LocationHelper.sharedInstance.displayLocation()
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Your location", comment: "Your location - title"),
                message:  locationDisplay,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
		}
			
		else {
            let locationDisplay:String = LocationHelper.sharedInstance.displayLocation()
            let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Your location cannot be determined", comment: "Your location not determined - title"),
                message:  locationDisplay,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment:""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
		}
	}
	
	//MARK: View Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.clearsSelectionOnViewWillAppear = false
		
		NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kLocationHelperNotification), object:nil, queue:nil) { _ in
			self.updateLocationButtonIcon()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return self.sectionTitles.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell:CollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as!CollectionViewCell

		cell.titleLabel.text = self.sectionTitles[indexPath.row]
	
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		if indexPath.row == 0 {
			let sectionController:PeakFlowViewController = storyboard.instantiateViewController(withIdentifier: "peakflow") as! PeakFlowViewController
			sectionController.flowAverageLabel = cell.subTitleLabel
			sectionController.updateDisplay()
			cell.controller = sectionController as UIViewController
		} else if indexPath.row == 1 {
			let sectionController:InhalerViewController = storyboard.instantiateViewController(withIdentifier: "inhaler") as! InhalerViewController
			sectionController.inhalerAverageLabel = cell.subTitleLabel
			sectionController.updateDisplay()
			cell.controller = sectionController as UIViewController
		}
		
		cell.contents.addSubview(cell.controller.view)
		
		cell.contents.addConstraint(NSLayoutConstraint(item: cell.controller.view, attribute: .leading, relatedBy: .equal, toItem: cell.contents, attribute: .leading, multiplier: 1.0, constant: 0.0))
		
		cell.contents.addConstraint(NSLayoutConstraint(item: cell.controller.view, attribute: .trailing, relatedBy: .equal, toItem: cell.contents, attribute: .trailing, multiplier: 1.0, constant: 0.0))
		
		cell.contents.addConstraint(NSLayoutConstraint(item: cell.controller.view, attribute: .top, relatedBy: .equal, toItem: cell.contents, attribute: .top, multiplier: 1.0, constant: 0.0))
		
		cell.contents.addConstraint(NSLayoutConstraint(item: cell.controller.view, attribute: .bottom, relatedBy: .equal, toItem: cell.contents, attribute: .bottom, multiplier: 1.0, constant: 0.0))

		cell.controller.view.translatesAutoresizingMaskIntoConstraints = false
		cell.controller.view.sizeToFit()
		cell.controller.view.layoutIfNeeded()
		cell.setNeedsDisplay()

        return cell
    }

    // MARK: UICollectionViewDelegate

    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		
		self.selectedSection = indexPath
		collectionView.performBatchUpdates({ () -> Void in
		}, completion: { (Bool) -> Void in
		})
		
        return true
    }

	override func collectionView(_ collectionView: UICollectionView,
		viewForSupplementaryElementOfKind kind: String,
		at indexPath: IndexPath) -> UICollectionReusableView
	{
		var view:UICollectionReusableView? = nil;
		
		if kind == UICollectionElementKindSectionHeader {
			view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
		}
		else if kind == UICollectionElementKindSectionFooter {
			view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath) 
			
			for subview in view!.subviews {
				if let buttonView:UIButton = subview as? UIButton {
					if buttonView.tag == 1 {
						self.locationButton = buttonView
						self.locationButton.addTarget(self, action: #selector(CollectionViewController.locationAction(_:)), for: UIControlEvents.touchUpInside)
						updateLocationButtonIcon()
						break;
					}
				}
			}
		}
		
		return view!;
	}
	
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

	//Mark: - UICollectionViewDelegateFlowLayout
 
	let cellSpacing:CGFloat = 5.0
	let headerHeight:CGFloat = 22.0
	let footerHeight:CGFloat = 50.0
	let minHeight:CGFloat = 50.0

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
	{
		let sectionCount = CGFloat(self.sectionTitles.count)
		
		var retval:CGSize = collectionView.frame.size;
		
		if indexPath.row == self.selectedSection.row {
			retval.height = retval.height - ((minHeight + cellSpacing) * (sectionCount - 1.0)) - (headerHeight + footerHeight)
		} else {
			retval.height = minHeight
		}
		
		return retval
	}
	
//	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
//	{
//		return UIEdgeInsetsMake(20, 0, 0, 0);
//	}

	func collectionView(_ collectionView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
	{
		return cellSpacing
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return cellSpacing
	}
	
	func collectionView(_ collectionView: UICollectionView, layout
		collectionViewLayout: UICollectionViewLayout,
		referenceSizeForHeaderInSection section: Int) -> CGSize
	{
		var retval:CGSize = collectionView.frame.size;
		retval.height = headerHeight
		return retval
	}
	
	func collectionView(_ collectionView: UICollectionView, layout
		collectionViewLayout: UICollectionViewLayout,
		referenceSizeForFooterInSection section: Int) -> CGSize
	{
		var retval:CGSize = collectionView.frame.size;
		retval.height = footerHeight
		return retval
	}

	//Mark: Utilities
	func updateLocationButtonIcon() {
		let userPref:Bool = LocationHelper.sharedInstance.trackLocationPref
		let accessAuth:Bool = LocationHelper.sharedInstance.accessAuthorized
		let locationResolved:Bool = LocationHelper.sharedInstance.locationResolved
		
		if !userPref {
			self.locationButton.isEnabled = false;
		}
			
		else if userPref && !accessAuth {
			self.locationButton.isEnabled = true;
			let image:UIImage? = UIImage(named:"warning")
			self.locationButton.setImage(image, for: UIControlState());
		}
			
		else if userPref && !locationResolved {
			self.locationButton.isEnabled = true;
			let image:UIImage? = UIImage(named:"location empty")
			self.locationButton.setImage(image, for: UIControlState());
		}
			
		else {
			self.locationButton.isEnabled = true;
			let image:UIImage? = UIImage(named:"location")
			self.locationButton.setImage(image, for: UIControlState());
		}
	}

}
