//
//  LocationManager.swift
//  Tee
//
//  Created by Aditya Chinchure on 2018-10-23.
//  Copyright © 2018 ThirdEyeOrganization. All rights reserved.
//

import AVFoundation
import MapKit
import CoreLocation


class LocationManager: NSObject, CLLocationManagerDelegate{
    let locationManager = CLLocationManager()
    
    func returnLatLong() -> [String] {
        
        locationManager.requestWhenInUseAuthorization()
        var currentLocation: CLLocation!
        var locArr:[String] = []
        
        if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways){
            
            currentLocation = locationManager.location
            
            locArr.append("\(currentLocation.coordinate.latitude)")
            locArr.append("\(currentLocation.coordinate.longitude)")
            
        }
        
        return locArr
    }
    
}
