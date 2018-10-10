//
//  Transit-StopParser.swift
//  Tee
//
//  Created by Aditya Chinchure on 2018-10-09.
//  Copyright © 2018 ThirdEyeOrganization. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class StopParser: NSObject, XMLParserDelegate {
    
    var currentParsingElement = ""
    var currStopNo = ""
    var busArray:Array<Bus> = []
    
    let semaphore = DispatchSemaphore(value: 0)
    
    func parseBuses(latString:String, longString:String) -> Array<Bus>{
        
        let url = URL(string: "https://api.translink.ca/rttiapi/v1/stops?apikey=BYuqozztjF6ZfjC8zuPI&lat=\(latString)&long=\(longString)&radius=200")
        
        //Creating data task
        let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) in
            if data == nil {
                print("dataTaskWithRequest error: \(String(describing: error?.localizedDescription))")
                return
            }
            let parser = XMLParser(data: data!)
            parser.delegate = self
            DispatchQueue.global(qos: .background).async {
                parser.parse()
            }
        }
        task.resume()
        self.semaphore.wait()
        return busArray
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentParsingElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let foundedChar = string.trimmingCharacters(in:NSCharacterSet.whitespacesAndNewlines)
        if (!foundedChar.isEmpty) {
            if currentParsingElement == "StopNo" {
                if(currStopNo == "") {
                    currStopNo = foundedChar
                }
            }
            else if currentParsingElement == "Error" {
                print("Error - unable to parse stop")
            }
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
 
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if(currStopNo != ""){
            let busParser = BusParser()
            busArray = busParser.findBuses(stopNo: currStopNo)
        } else {
            print("Error - parsing did not complete successfully")
        }
        self.semaphore.signal()
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("parseErrorOccurred: \(parseError)")
    }
    
}
