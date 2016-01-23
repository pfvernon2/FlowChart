//
//  CSVHelper.swift
//  Flowchart
//
//  Created by Frank Vernon on 10/28/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

class CSVHelper: NSObject {
	
	let delimiter:Character = ","
	
	func read(contentsOfURL url: NSURL, useEncoding encoding: UInt = NSUTF8StringEncoding) -> [[String]] {
		let characterData:String = try! String(contentsOfFile: url.path!, encoding: encoding)
		var table:[[String]] = []
		
		var quoted:Bool = false
		var testEscaped:Bool = false
		var testRecordEnd:Bool = false
		var field:String = ""
		var record:[String] = []
		for current:Character in characterData.characters {
			if testEscaped && current != "\"" {
				testEscaped = false
				quoted = false
			}
			
			//check for escape sequence start
			if current == "\"" && quoted && !testEscaped {
				testEscaped = true
				continue
			}
				
            //check for quote sequence start
			else if current == "\"" && !testEscaped {
				quoted = !quoted
			}
				
            //if not quoted check for record delimiter(s)
            // supporting bare CR & LF, not required by RFC4180 but common
			else if !quoted && (current == "\r" || current == "\n") {
				testRecordEnd = true
				continue
			}
                
			else if !quoted && (current == "\r\n" || testRecordEnd) {
				record.append(field)
				table.append(record)
				record = []
				field = ""
				if testRecordEnd {
					field.append(current)
				}
			}
				
            //if not quoted check for field delimiter
			else if !quoted && current == self.delimiter {
				record.append(field)
				field = ""
			}
				
            //add character to current field
			else {
				field.append(current)
			}
			
			testEscaped = false
			testRecordEnd = false
		}
		
		return table
	}
	
	func write(table: [[String]], toFile url: NSURL, useEncoding encoding: UInt = NSUTF8StringEncoding) {
		var output:String = String()
		
		for (_, record) in table.enumerate() {
			var row:String = ""
			for (_, field) in record.enumerate() {
				let escaped = field.stringByReplacingOccurrencesOfString("\"", withString: "\"\"", options: NSStringCompareOptions.LiteralSearch, range: nil)
				let quoted = "\"" + escaped + "\""
				
				if row.characters.count > 0 {
					row += ","
				}
				row += quoted
			}
			
			row += "\r\n"
			output += row
		}
		
		do {
			try output.writeToURL(url, atomically: true, encoding: encoding)
		} catch _ {
		}
	}
}
