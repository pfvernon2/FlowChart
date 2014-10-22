//
//  CSVReader.swift
//  Flowchart
//
//  RFC4180 CSV parser. Attempts to be easy on memory even for arbitrarily large files
//
//  Created by Frank Vernon on 10/22/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

public class CSVReader {
    
    let delimiter:Character = ","
    var source:NSMutableData
    var characterData:String
    var characterDataSize = 0
	var indexPosition = 0

    public init(contentsOfURL url: NSURL, useEncoding encoding: UInt = NSUTF8StringEncoding) {
        //load data into String via a memory mapped NSData object to allow for large file parsing
        var error: NSErrorPointer  = nil;
        self.source = NSMutableData(contentsOfFile: url.path!, options: .DataReadingMappedIfSafe, error: error)!
		self.characterData = NSString(bytesNoCopy: self.source.mutableBytes, length: self.source.length, encoding: encoding, freeWhenDone: false)!
		self.characterDataSize = countElements(characterData)
    }
    
    //read entire file into memory, returns array of arrays
    func table() -> [[String]] {
        var result:[[String]] = []

        while let row = self.nextRow() {
            result.append(row)
        }

        return result
    }
    
    //read next row from data set, returns nil at end of file
    func nextRow() -> [String]? {
        if self.indexPosition >= countElements(characterData) {
            return nil
        }
        
        var result:[String] = []
        
        var quoted:Bool = false
        var testEscaped:Bool = false
        var testRecordEnd:Bool = false
        var field:String = ""
        while self.indexPosition < self.characterDataSize {
            let current:Character = characterData[advance(characterData.startIndex, self.indexPosition++)]
            
            //check for escape sequence start
            if current == "\"" && quoted && !testEscaped {
                testEscaped = true
                continue
            }
                
                //check for quote sequence start
            else if current == "\"" && !testEscaped {
                quoted = !quoted
            }
                
                //if not quoted check for record delimiters
			else if !quoted && current == "\r\n" {
				result.append(field)
				break
			}
				//support bare CR & LF, not required by RFC4180 but common
            else if !quoted && (current == "\r" || current == "\n") {
                testRecordEnd = true
                continue
            }
			else if testRecordEnd {
				--self.indexPosition
				result.append(field)
				break
			}
				
                //if not quoted check for field delimiter
            else if !quoted && current == self.delimiter {
                result.append(field)
                field = ""
            }
                
                //add character to current field
            else {
                field.append(current)
            }
            testEscaped = false
            testRecordEnd = false
        }
        
        return result
    }
}
