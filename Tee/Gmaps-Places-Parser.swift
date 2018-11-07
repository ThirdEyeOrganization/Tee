//
//  Gmaps-Places-Parser.swift
//  Tee
//
//  Created by Aditya Chinchure on 2018-11-06.
//  Copyright © 2018 ThirdEyeOrganization. All rights reserved.
//

import Foundation

class GmapsPlacesParser: NSObject {
    
    var API_KEY = Properties().GOOGLE_API_KEY
    
    var lat = ""
    var long = ""
    var radius = "100"
    var type = "restaurant "
    
    func findPlaces(lat:String, long:String){
        self.lat = lat
        self.long = long
        getJsonFromUrl()
    }

    var nameArray = [String]()
    
    func getJsonFromUrl(){
        //creating a NSURL
        guard let url = NSURL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(long)&radius=\(radius)&key=\(API_KEY)") else {return}
        
        let task = URLSession.shared.dataTask(with: (url as URL?)!) {(data, response, error) in
            guard let dataResponse = data,
                error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return }
            do {
                //here dataResponse received from a network request
                let jsonResponse = try JSONSerialization.jsonObject(with:
                    dataResponse, options: [])
                print(jsonResponse) //Response result
            } catch let parsingError {
                print("Error", parsingError)
            }
        }
        task.resume()
    }
    
}
