//
//  UPC-Parser.swift
//  Tee
//
//  Created by Aditya Chinchure on 2018-10-15.
//  Copyright © 2018 ThirdEyeOrganization. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class UPCParser: NSObject {
    
    func parseUPC(upccode:Int) -> String{
        if upccode > 0 && upc != upccode {
            upc = upccode
            return getJsonFromUrl()
        }else{
            return ""
        }
    }
    var upc = 885909950805
    var nameArray = [String]()
    
    func getJsonFromUrl() -> String {
        //creating a NSURL
        let url = NSURL(string: "https://api.upcitemdb.com/prod/trial/lookup?upc=\(upc)")
        var linkStr = ""
        
        //fetching the data from the url
        URLSession.shared.dataTask(with: (url as URL?)!, completionHandler: {(data, response, error) -> Void in
            
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                
                if jsonObj != nil {
                    
                    //printing the json in console
                    print(jsonObj!.value(forKey: "items") ?? "failed")
                    //getting the avengers tag array from json and converting it to NSArray
                    if let itemsArray = jsonObj!.value(forKey: "items") as? NSArray {
                        //looping through all the elements
                        for item in itemsArray{
                            //converting the element to a dictionary
                            if let offersArray = (item as AnyObject).value(forKey: "offers") as? NSArray {
                                
                                for offer in offersArray {
                                    
                                    if let offerDict = offer as? NSDictionary {
                                        
                                        if let link = offerDict.value(forKey: "link") {
                                            
                                            linkStr = link as! String
                                            
                                        }
                                        
                                    }
                                    
                                }
                            }
                        }
                    }
                
                OperationQueue.main.addOperation({
                    //calling another function after fetching the json
                    //it will show the names to label
                    for name in self.nameArray{
                        print(name)
                    }
                })
            }
            }
        }).resume()
        return linkStr
    }
    
}
