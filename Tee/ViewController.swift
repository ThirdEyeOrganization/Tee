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


class ViewController: UIViewController{
    // initialize CLLocation
   
    enum CardState {
        case expanded
        case collapsed
    }
    
    var cardViewController:WebViewController!
    var visualEffectView:UIVisualEffectView!
    
    let topHeight: CGFloat = 80
    var cardHeight:CGFloat = 600
    let cardHandleAreaHeight:CGFloat = 65
    var isWebViewOpen:Bool = false
    
    var cardVisible = false
    var nextState:CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted:CGFloat = 0
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var transitButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var weatherButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var qrCodeButton: UIButton!
    @IBOutlet weak var calendarButton: UIButton!
    @IBOutlet weak var choiceLabel: UILabel!
    @IBOutlet weak var buttonScrollView: UIScrollView!
    
    var buttons: [UIButton] = []
    var numButtons = 7
    var selected = 0
    var prevSelected = 0
    var settingsSelected: Bool = false
    
    
    @IBAction func calendarButtonClicked(_ sender: Any) {
        killMetadataScanner()
        setButtonToSelectedWhenButtonPressed(index: 4)
    }
    @IBAction func qrCodeButtonClicked(_ sender: Any) {
        killMetadataScanner()
        setButtonToSelectedWhenButtonPressed(index: 5)
        initiateMetadataScanner()
    }
    @IBAction func cameraButtonClicked(_ sender: Any) {
        killMetadataScanner()
        setButtonToSelectedWhenButtonPressed(index: 0)
    }
    @IBAction func transitButtonClicked(_ sender: Any) {
        killMetadataScanner()
        setButtonToSelectedWhenButtonPressed(index: 2)
        busStop()
    }
    @IBAction func mapButtonClicked(_ sender: Any) {
        killMetadataScanner()
        setButtonToSelectedWhenButtonPressed(index: 1)
        findPlaces()
    }
    @IBAction func weatherButtonClicked(_ sender: Any) {
        killMetadataScanner()
        setButtonToSelectedWhenButtonPressed(index: 3)
    }
    @IBAction func settingsButtonClicked(_ sender: Any) {
        killMetadataScanner()
        setButtonToSelectedWhenButtonPressed(index: 6)
    }
    
    func findPlaces() {
        let locManager = LocationManager()
        var locArr:[String] = locManager.returnLatLong()
        while(locArr.isEmpty){
            locArr = locManager.returnLatLong()
        }
        
        let latString:String = String(locArr[0].prefix(9))
        let longString:String = String(locArr[1].prefix(11))
        
        let placesParser = GmapsPlacesParser()
        placesParser.findPlaces(lat: latString, long: longString)
        let dict = ["UBC":[49.2611816, -123.2465066]]
        printLocationsAndDistances(parsedDict: dict)
    }
    
    func printLocationsAndDistances(parsedDict: Dictionary<String, [Double]>){
        let locManager = LocationManager()
        var locArr:[String] = locManager.returnLatLong()
        let currCoord = CLLocation(latitude: Double(locArr[0]) ?? 0, longitude: Double(locArr[1]) ?? 0)
        for (name, coord) in parsedDict {
            let placeCoord = CLLocation(latitude: coord[0], longitude: coord[1])
            let distanceInMeters = currCoord.distance(from: placeCoord)
            print("\(name) is \(distanceInMeters) meters away and at at angle of \(getBearingBetweenTwoPoints1(point1: currCoord, point2: placeCoord)) degrees")
        }
    }
    
    func getBearingBetweenTwoPoints1(point1 : CLLocation, point2 : CLLocation) -> Double {
        
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radians: radiansBearing)
    }
    
    func degreesToRadians(degrees : Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    func radiansToDegrees(radians : Double) -> Double {
        return radians * 180.0 / .pi
    }
    
    func busStop() {
        
        let locManager = LocationManager()
        var locArr:[String] = locManager.returnLatLong()
        while(locArr.isEmpty){
            locArr = locManager.returnLatLong()
        }
        
        let latString:String = String(locArr[0].prefix(9))
        let longString:String = String(locArr[1].prefix(11))

        let stopParser = StopParser()
        let buses = stopParser.parseBuses(latString: latString, longString: longString)
        
        var alertMsgStr = ""
        var stopNo = ""
        
        if (buses.count > 0){
            for i in 0...(buses.count-1){
                //TODO - add UI functionality!
                print("At bus stop no. \(buses[i].getStopNo()):")
                print("Bus \(buses[i].getRouteNo()) to \(buses[i].getDestination()) will arrive in \(buses[i].getExpectedCountdown())")
                
                stopNo = buses[i].getStopNo()
                alertMsgStr.append(contentsOf: "Bus \(buses[i].getRouteNo()) to \(buses[i].getDestination()) will arrive in \(buses[i].getExpectedCountdown()) \n")
            }
            
            //showing an alert prompt
            let alertPrompt = UIAlertController(title: "Stop \(stopNo)", message: alertMsgStr, preferredStyle: .actionSheet)
            
            let cancelAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil)
            
            alertPrompt.addAction(cancelAction)
            present(alertPrompt, animated: true, completion: nil)
        }
    }
    
    
    
    var captureSession = AVCaptureSession()
    
    var upcval:String = ""
    var lastLink = ""
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var captureMetadataOutput: AVCaptureMetadataOutput? = nil
    
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
        cardHeight = self.view.frame.height - topHeight
        
        
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
            captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput!)
            
            // Set delegate and use the default dispatch queue to execute the call back
            //captureMetadataOutput.setMetadataObjectsDelegate(nil, queue: DispatchQueue.main)
            captureMetadataOutput!.metadataObjectTypes = supportedCodeTypes
            //captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
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
        
        view.bringSubviewToFront(choiceLabel)
        view.bringSubviewToFront(buttonScrollView)
        choiceLabel.layer.cornerRadius = 45
        choiceLabel.layer.masksToBounds = true
        choiceLabel.layer.borderColor = UIColor.white.cgColor
        choiceLabel.layer.borderWidth = 6
        buttonScrollView.delegate = self
        buttons = [cameraButton, mapButton, transitButton, weatherButton, calendarButton, qrCodeButton, settingsButton]
        numButtons = buttons.count
        createButtonScrollView()
        setButtonToSelected(index: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helper methods
    
    func initiateMetadataScanner(){
        captureMetadataOutput!.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }
    
    func killMetadataScanner(){
        captureMetadataOutput!.setMetadataObjectsDelegate(nil, queue: DispatchQueue.main)
    }
    
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
    
    func createButtonScrollView(){
        var pw = Int(UIScreen.main.bounds.size.width)
        buttonScrollView.contentSize = CGSize.init(width: (numButtons*90+2*(pw/2-60)), height: 80)
        buttonScrollView.isScrollEnabled = true
        buttonScrollView.isUserInteractionEnabled = true
        buttonScrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        var px:Int = (pw/2)-60
        var py:Int = 0
        for k in 0...(numButtons-1){
            let button = buttons[k]
            button.frame = CGRect(x: px+30, y: py+10, width: 60, height: 60)
            buttonScrollView.addSubview(button)
            px += 90
        }
    }
    
    func setButtonToSelectedWhenButtonPressed(index: Int){
        if selected == index {
            return
        }
        if index == numButtons-1 {
            settingsSelected = true
        }
        selected = index
        print("Set selected on click to \(selected)")
        var offsets: [Int] = []
        for i in 0...(numButtons-1){
            offsets.append(i*90)
        }
        let closest = offsets[index]
        buttonScrollView.setContentOffset(CGPoint(x: closest, y: 0), animated: true)
        setButtonToSelected(index: index)
    }
    
    func setButtonToSelected(index: Int){
        let button = buttonScrollView.subviews[index]
        button.frame = button.frame.insetBy(dx: -9, dy: -9)
    }
    
    func resetButtons(){
        let subViews = buttonScrollView.subviews
        for subview in subViews{
            subview.removeFromSuperview()
        }
        let pw = Int(UIScreen.main.bounds.size.width)
        var px:Int = (pw/2)-60
        let py:Int = 0
        for button in buttons {
            button.frame = CGRect(x: px+30, y: py+10, width: 60, height: 60)
            buttonScrollView.addSubview(button)
            px += 90
        }
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
                let number = Int(metadataObj.stringValue!)
                if number != nil {
                    
                    let upcParser = UPCParser()
                    let link = upcParser.parseUPC(upccode: number!)
                    if Int(upcval) != number || lastLink != link{
                        lastLink = link
                        if link != "" && verifyUrl(urlString: link) && !isWebViewOpen {
                            print("the link is"+link)
                            setupCard(urlStr: link)
                        }
                    }
                }else{
                    //launchApp(decodedURL: metadataObj.stringValue!)
                    let link = metadataObj.stringValue!
                    if link != "" && verifyUrl(urlString: link) && !isWebViewOpen {
                        print("this is a link"+link)
                        setupCard(urlStr: link)
                    }
                }
                
            }
        }
    }
    
    func verifyUrl(urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = URL(string: urlString) {
                return UIApplication.shared.canOpenURL(url)
            }
        }
        return false
    }
    
}


extension ViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        var offsets: [Int] = []
        for i in 0...(numButtons-1){
            offsets.append(i*90)
        }
        
        let currOffset = Int(buttonScrollView.contentOffset.x)
        var closest = offsets.enumerated().min( by: { abs($0.1 - currOffset) < abs($1.1 - currOffset) } )!
        if (!settingsSelected && closest.offset == offsets.count-1){
            closest.element = offsets[offsets.count-2]
            closest.offset = closest.offset-1
        }
        selected = closest.offset
        buttonScrollView.setContentOffset(CGPoint(x: closest.element, y: 0), animated: true)
        print("Set selected on scroll to \(selected)")
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDidEndDecelerating(buttonScrollView)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(buttonScrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(buttonScrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(buttonScrollView)
        settingsSelected = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        resetButtons()
        setButtonToSelected(index: selected)
    }
    
    func setupCard(urlStr:String) {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        
        cardViewController = WebViewController(nibName:"WebView", bundle:nil)
        self.addChild(cardViewController)
        self.view.addSubview(cardViewController.view)
        
        cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - self.cardHandleAreaHeight, width: self.view.bounds.width, height: cardHeight)
        
        cardViewController.view.clipsToBounds = true
        
        cardViewController.webView.load(URLRequest(url: URL(string: urlStr)!))
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleCardTap(recognzier:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handleCardPan(recognizer:)))
        
        cardViewController.handleBar.addGestureRecognizer(tapGestureRecognizer)
        cardViewController.handleBar.addGestureRecognizer(panGestureRecognizer)
        
        isWebViewOpen = true
        
        animateTransitionIfNeeded(state: nextState, duration: 0.9)
    }
    
    @objc
    func handleCardTap(recognzier:UITapGestureRecognizer) {
        //switch recognzier.state {
        //case .ended:
            //animateTransitionIfNeeded(state: nextState, duration: 0.9)
        //default:
        //    break
        //}
    }
    
    @objc
    func handleCardPan (recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: self.cardViewController.handleBar)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height
                    self.isWebViewOpen = false
                    self.visualEffectView.removeFromSuperview()
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = 24
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
            
        }
    }
    
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition (){
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}
