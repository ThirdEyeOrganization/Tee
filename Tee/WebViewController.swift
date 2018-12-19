//
//  WebViewController.swift
//  Tee
//
//  Created by Aditya Chinchure on 2018-11-30.
//  Copyright © 2018 ThirdEyeOrganization. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate{

    @IBOutlet weak var handleBar: UIView!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        urlLabel.text = webView.title
    }
    
    @IBAction func backButton(_ sender: Any) {
        if(webView.canGoBack) {
            webView.goBack()
            urlLabel.text = webView.title
        }
    }
    
    @IBAction func forwardButton(_ sender: Any) {
        if(webView.canGoForward) {
            webView.goForward()
            urlLabel.text = webView.title
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        let url = webView.url
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        urlLabel.text = components?.host
        if (url?.absoluteString.hasPrefix("https://"))!{
            urlLabel.textColor = #colorLiteral(red: 0.01960784314, green: 0.4588235294, blue: 0.2588235294, alpha: 1)
        }else{
            urlLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }

}
