//
//  CSVWriter.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/23/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

class CSVWriter: NSObject {
 
	let delimiter:Character = ","
	var sinkFile:NSURL?
	var outputEncoding:UInt
	
	init(file url: NSURL, useEncoding encoding: UInt = NSUTF8StringEncoding) {
		sinkFile = url
		outputEncoding = encoding
	}

	func write(table: [[String]]) {
		var output:String = String()
		
		for (recordIndex, record) in enumerate(table) {
			var row:String = ""
			for (fieldIndex, field) in enumerate(record) {
				var escaped = field.stringByReplacingOccurrencesOfString("\"", withString: "\"\"", options: NSStringCompareOptions.LiteralSearch, range: nil)
				var quoted = "\"" + escaped + "\""

				if countElements(row) > 0 {
					row += ","
				}
				row += quoted
			}
			
			row += "\r\n"
			output += row
		}
		
		output.writeToURL(self.sinkFile!, atomically: true, encoding: self.outputEncoding, error: nil)
	}
}
