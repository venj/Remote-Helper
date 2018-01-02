//
//  WebViewController.swift
//  Remote Helper
//
//  Created by venj on 1/2/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import TOWebViewController

class WebViewController: TOWebViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Theme
        loadingBarTintColor = Helper.shared.mainThemeColor()
        if UIDevice.current.userInterfaceIdiom == .phone {
            buttonTintColor = Helper.shared.mainThemeColor()
        }
        else {
            buttonTintColor = UIColor.white
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType != .linkClicked { return super.webView(webView, shouldStartLoadWith: request, navigationType: navigationType) }
        if request.url?.host == self.url?.host {
            return super.webView(webView, shouldStartLoadWith: request, navigationType: navigationType)
        }
        else {
            return false
        }
    }
}
