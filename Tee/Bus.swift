//
//  Bus.swift
//  Tee
//
//  Created by Aditya Chinchure on 2018-10-09.
//  Copyright © 2018 ThirdEyeOrganization. All rights reserved.
//

import Foundation

class Bus: NSObject{
    
    var stopNo:String = "Error"
    var routeNo:String = "Error"
    var destination:String = "Error"
    var expectedTime:String = "Error"
    var expectedCountdown:String = "Error"
    
    init(stopNo:String, routeNo:String, destination:String, expectedTime:String, expectedCountdown:String) {
        self.stopNo = stopNo
        self.routeNo = routeNo
        self.destination = destination
        self.expectedTime = expectedTime
        self.expectedCountdown = expectedCountdown
    }
    
    func setStopNo(stopNo:String){
        self.stopNo = stopNo
    }
    func setRouteNo(routeNo:String){
        self.routeNo = routeNo
    }
    func setDestination(destination:String){
        self.destination = destination
    }
    func setExpectedTime(expectedTime:String){
        self.expectedTime = expectedTime
    }
    func setExpectedCountdown(expectedCountdown:String){
        self.expectedCountdown = expectedCountdown
    }
    
    func getStopNo() -> String {
        return self.stopNo
    }
    func getRouteNo() -> String {
        return self.routeNo
    }
    func getDestination() -> String {
        return self.destination
    }
    func getExpectedTime() -> String {
        return self.expectedTime
    }
    func getExpectedCountdown() -> String {
        return self.expectedCountdown
    }
}
