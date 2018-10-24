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
    
    func parseUPC(upccode:Int){
        upc = upccode
        getJsonFromUrl()
    }
    var upc = 885909950805
    var nameArray = [String]()
    
    func getJsonFromUrl(){
        //creating a NSURL
        let url = NSURL(string: "https://api.upcitemdb.com/prod/trial/lookup?upc=\(upc)")
        
        //fetching the data from the url
        URLSession.shared.dataTask(with: (url as URL?)!, completionHandler: {(data, response, error) -> Void in
            
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                
                //printing the json in console
                print(jsonObj!.value(forKey: "items")!)
                //getting the avengers tag array from json and converting it to NSArray
                if let itemsArray = jsonObj!.value(forKey: "items") as? NSArray {
                    //looping through all the elements
                    for item in itemsArray{
                        //converting the element to a dictionary
                        if let itemDict = item as? NSDictionary {
                            //getting the name from the dictionary
                            if let name = itemDict.value(forKey: "title") {
                                //adding the name to the array
                                self.nameArray.append((name as? String)!)
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
        }).resume()
    }
    
}
