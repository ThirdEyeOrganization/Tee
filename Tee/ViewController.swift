//
//  ViewController.swift
//  Tee
//
//  Created by Prakhar Tripathi on 2018-09-20.
//  Copyright © 2018 ThirdEyeOrganization. All rights reserved.
//

import UIKit
import AVFoundation
import MapKit
import CoreLocation



class ViewController: UIViewController, CLLocationManagerDelegate, XMLParserDelegate{
    // initialize CLLocation
   
    let locationManager = CLLocationManager()
    var parser = XMLParser()
    
    @IBOutlet weak var busButton: UIButton!
    
    @IBAction func busStop(_ sender: Any) {
        getXMLDataFromServer()
    }
    
    func getXMLDataFromServer(){
        // Do any initiation for CORELOCATION
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        let latitude = locationManager.location?.coordinate.latitude
        let longitude = locationManager.location?.coordinate.longitude
        let latString:String = String("\(String(describing: latitude!))".prefix(9))
        let longString:String = String("\(String(describing: longitude!))".prefix(11))
        
        let url = URL(string: "https://api.translink.ca/rttiapi/v1/stops?apikey=BYuqozztjF6ZfjC8zuPI&lat=\(latString)&long=\(longString)&radius=7")
        print("https://api.translink.ca/rttiapi/v1/stops?apikey=BYuqozztjF6ZfjC8zuPI&lat=\(latString)&long=\(longString)&radius=7")
        
        //Creating data task
        let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) in
            
            if data == nil {
                print("dataTaskWithRequest error: \(String(describing: error?.localizedDescription))")
                return
            }
            
            let parser = XMLParser(data: data!)
            parser.delegate = self
            parser.parse()
            
        }
        
        task.resume()
        
    }
    
    var currentParsingElement = ""
    var currStopNo = ""
    var stopNo = ""
    var routeNoArray: Array<String> = []
    var destinationArray: Array<String> = []
    var expectedCountdownArray: Array<String> = []
    
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        print(elementName)
        currentParsingElement = elementName
        if elementName == "Response" {
            print("Started parsing...")
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let foundedChar = string.trimmingCharacters(in:NSCharacterSet.whitespacesAndNewlines)
        if (!foundedChar.isEmpty) {
            if currentParsingElement == "StopNo" {
                if(currStopNo == "") {
                    currStopNo = foundedChar
                }
            }
            else if currentParsingElement == "RouteNo" {
                routeNoArray.append(foundedChar)
            }
            else if currentParsingElement == "Destination" {
                destinationArray.append(foundedChar)
            }
            else if currentParsingElement == "ExpectedCountdown" {
                expectedCountdownArray.append(foundedChar)
            }
            else if currentParsingElement == "Error" {
                print("There is an error")
                stopNo = "ERROR"
            }
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Response" {
            print("Ended parsing...")
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print(currStopNo)
        if(currStopNo != ""){
            stopNo = currStopNo
            findBusInfo()
        } else {
            print(routeNoArray)
            print(destinationArray)
            print(expectedCountdownArray)
            let alertPrompt = UIAlertController(title: "Stop \(stopNo)", message: "routeNum: \(routeNoArray) dest: \(destinationArray) time: \(expectedCountdownArray)", preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
            alertPrompt.addAction(cancelAction)
            present(alertPrompt, animated: true, completion: nil)
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("parseErrorOccurred: \(parseError)")
    }

    func findBusInfo(){
        
        let url = URL(string: "http://api.translink.ca/rttiapi/v1/stops/\(currStopNo)/estimates?apikey=BYuqozztjF6ZfjC8zuPI&count=1")
        print("http://api.translink.ca/rttiapi/v1/stops/\(currStopNo)/estimates?apikey=BYuqozztjF6ZfjC8zuPI&count=1")
        currStopNo = ""
        
        //Creating data task
        let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) in
            if data == nil {
                print("dataTaskWithRequest error: \(String(describing: error?.localizedDescription))")
                return
            }
            
            let parser = XMLParser(data: data!)
            parser.delegate = self
            parser.parse()
        }
        
        task.resume()
        
    }
    
    var captureSession = AVCaptureSession()
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    let notification = UINotificationFeedbackGenerator()
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            //            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        captureSession.startRunning()
        
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
        
        view.bringSubviewToFront(busButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helper methods
    
    func launchApp(decodedURL: String) {
        
        if presentedViewController != nil {
            notification.notificationOccurred(.error)
            return
        }
        
        let alertPrompt = UIAlertController(title: "Open App", message: "This requires you to open the \(decodedURL)", preferredStyle: .actionSheet)
        notification.notificationOccurred(.success)
        let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { (action) -> Void in
            
            if let url = URL(string: decodedURL) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        
        alertPrompt.addAction(confirmAction)
        alertPrompt.addAction(cancelAction)
        
        present(alertPrompt, animated: true, completion: nil)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        //print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            notification.notificationOccurred(.error)
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                launchApp(decodedURL: metadataObj.stringValue!)
            }
        }
    }
    
}

