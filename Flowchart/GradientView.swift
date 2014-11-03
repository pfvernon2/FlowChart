//
//  GradientView.swift
//  Flowchart
//
//  Created by Frank Vernon on 11/2/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

class GradientView: UIView {
	
	var gradientLayer:CAGradientLayer?

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.applyGradient(frame)
	}
 
	required init(coder: NSCoder) {
		super.init(coder: coder)
		
		self.applyGradient(self.frame)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.applyGradient(self.frame)
	}
	
	func applyGradient(frame: CGRect) {
		if gradientLayer == nil {
			self.gradientLayer = CAGradientLayer()

			let colorTop = UIColor(red: 76.0/255.0, green: 233.0/255.0, blue: 204.0/255.0, alpha: 1.0).CGColor
			let colorBottom = UIColor(red: 52.0/255.0, green: 170.0/255.0, blue: 220.0/255.0, alpha: 1.0).CGColor
			self.gradientLayer!.colors = [colorTop, colorBottom]
			self.gradientLayer!.locations = [0.0, 1.0]
			
			self.backgroundColor = UIColor.clearColor()
			self.layer.insertSublayer(self.gradientLayer, atIndex: 0);
		}
		
		self.gradientLayer!.frame = frame
	}
}
