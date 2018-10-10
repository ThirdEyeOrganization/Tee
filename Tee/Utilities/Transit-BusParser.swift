//
//  Transit-BusParser.swift
//  Tee
//
//  Created by Aditya Chinchure on 2018-10-09.
//  Copyright © 2018 ThirdEyeOrganization. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class BusParser: NSObject, XMLParserDelegate {
    
    var currentParsingElement = ""
    var currStopNo = ""
    
    var buses: Array<Bus> = []
    
    var routeNoArray: Array<String> = []
    var destinationArray: Array<String> = []
    var expectedCountdownArray: Array<String> = []
    var expectedLeaveTimeArray: Array<String> = []
    
    let altSemaphore = DispatchSemaphore(value: 0)
    
    func findBuses(stopNo:String) -> Array<Bus>{
        
        currStopNo = stopNo
        
        let url = URL(string: "http://api.translink.ca/rttiapi/v1/stops/\(currStopNo)/estimates?apikey=BYuqozztjF6ZfjC8zuPI&count=1")
        
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
        self.altSemaphore.wait()
        return buses
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentParsingElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let foundedChar = string.trimmingCharacters(in:NSCharacterSet.whitespacesAndNewlines)
        if (!foundedChar.isEmpty) {
            if currentParsingElement == "RouteNo" {
                routeNoArray.append(foundedChar)
            }
            else if currentParsingElement == "Destination" {
                destinationArray.append(foundedChar)
            }
            else if currentParsingElement == "ExpectedCountdown" {
                expectedCountdownArray.append(foundedChar)
            }
            else if currentParsingElement == "ExpectedLeaveTime" {
                expectedLeaveTimeArray.append(foundedChar)
            }
            else if currentParsingElement == "Error" {
                print("Error - unable to parse buses")
            }
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
   
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if(!routeNoArray.isEmpty){
            createBuses()
        } else {
            print("Error - parsing buses did not complete successfully")
        }
        self.altSemaphore.signal()
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("parseErrorOccurred: \(parseError)")
    }
    
    func createBuses(){
        let len = routeNoArray.count
        if (len > 0){
            for i in 0...(len-1){
                let bus = Bus(stopNo: currStopNo, routeNo: routeNoArray[i], destination: destinationArray[i], expectedTime: expectedLeaveTimeArray[i], expectedCountdown: expectedCountdownArray[i])
                buses.append(bus)
            }
        }
    }
}

