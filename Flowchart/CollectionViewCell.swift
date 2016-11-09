//
//  CollectionViewCell.swift
//  Flowchart
//
//  Created by Frank Vernon on 11/4/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var subTitleLabel: UILabel!
	@IBOutlet var contents: UIView!
	var controller: UIViewController!
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.initCell();
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.initCell();
	}
	
	func initCell() {
		self.translatesAutoresizingMaskIntoConstraints = false;
		self.autoresizingMask = [.flexibleHeight, .flexibleWidth];
	}
	
//	override func drawRect(rect: CGRect) {
//		println(__FUNCTION__)
//
//		var color:UIColor = UIColor.redColor()
//		color.set()
//		
//		var bpath:UIBezierPath = UIBezierPath()
//		bpath.lineWidth = 2.0
//		bpath.moveToPoint(CGPointMake(rect.origin.x + 1.0, rect.origin.y + 1.0))
//		bpath.addLineToPoint(CGPointMake(rect.origin.x + self.titleLabel.frame.width + self.titleLabel.frame.origin.x + 10.0, rect.origin.y + 1.0))
//		bpath.addLineToPoint(CGPointMake(rect.origin.x + self.titleLabel.frame.width + self.titleLabel.frame.origin.x + 10.0,
//			rect.origin.y + 1.0 + self.titleLabel.frame.origin.y + self.titleLabel.frame.height + self.subTitleLabel.frame.height))
//
//		bpath.addLineToPoint(CGPointMake(rect.origin.x + rect.width - 1.0,
//			rect.origin.y + self.titleLabel.frame.origin.y + self.titleLabel.frame.height + self.subTitleLabel.frame.height))
//
//		bpath.addLineToPoint(CGPointMake(rect.origin.x - 1.0 + rect.width,
//			rect.origin.y + rect.height - 1.0))
//
//		bpath.addLineToPoint(CGPointMake(rect.origin.x + 1.0,
//			rect.origin.y + rect.height - 1.0 ))
//
//		
//		bpath.closePath()
//		
//		bpath.stroke()
//		
//	}
	
}

