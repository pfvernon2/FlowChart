//
//  CSVReader.swift
//  Flowchart
//
//  RFC4180 CSV parser. It does not do well with large files.
//		Everything done in memory for UNICODE support
//
//  Created by Frank Vernon on 10/22/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

public class CSVReader: NSObject {
	
	let delimiter:Character = ","
	var characterData:String
	
	public init(contentsOfURL url: NSURL, useEncoding encoding: UInt = NSUTF8StringEncoding) {
		self.characterData = String(contentsOfFile: url.path!, encoding: encoding, error: nil)!
	}
	
	//read entire file into memory, returns array of arrays
	func read() -> [[String]] {
		var table:[[String]] = []
		
		var quoted:Bool = false
		var testEscaped:Bool = false
		var testRecordEnd:Bool = false
		var field:String = ""
		var record:[String] = []
		for current:Character in self.characterData {
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
}
