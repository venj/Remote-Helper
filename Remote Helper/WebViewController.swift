//
//  WebViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 9/30/19.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    var webView: WKWebView!
    var urlString: String? {
        didSet {
            url = URL(string: urlString ?? "")
            if let url = url {
                urlRequest = URLRequest(url: url)
            }
        }
    }
    var isPeeking: Bool = false
    var additionalBarButtonItems: [UIBarButtonItem] = []
    var url: URL? = nil
    var urlRequest: URLRequest? = nil
    var reloadStopBarButtonItem: UIBarButtonItem!
    var navBackBarButtonItem: UIBarButtonItem!
    var navForwardBarButtonItem: UIBarButtonItem!

    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }

    convenience init(urlString: String?) {
        self.init(nibName: nil, bundle: nil)
        defer {
            self.urlString = urlString
        }
    }

    convenience init(url: URL?) {
        self.init(nibName: nil, bundle: nil)
        defer {
            self.urlString = url?.absoluteString
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let urlRequest = urlRequest {
            if title == nil || title! == "" {
                title = urlRequest.url?.host ?? ""
            }
            webView.load(urlRequest)
        }
        configureBarButtonItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupBarButtonItems()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if view.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            setupBarButtonItems()
        }
    }

    func setupBarButtonItems() {
        let flexspaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        if view.traitCollection.horizontalSizeClass == .compact {
            navigationController?.setToolbarHidden(false, animated: false)
            navigationController?.toolbar.setItems([flexspaceBarButtonItem, navBackBarButtonItem, flexspaceBarButtonItem, navForwardBarButtonItem, flexspaceBarButtonItem, reloadStopBarButtonItem, flexspaceBarButtonItem], animated: false)
            navigationItem.rightBarButtonItems = additionalBarButtonItems
        }
        else {
            navigationController?.toolbar.setItems([], animated: false)
            navigationController?.setToolbarHidden(true, animated: false)
            navigationItem.rightBarButtonItems = additionalBarButtonItems + [reloadStopBarButtonItem, navForwardBarButtonItem, navBackBarButtonItem]
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView?.stopLoading()
        navigationController?.setToolbarHidden(true, animated: false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func configureBarButtonItems() {
        reloadStopBarButtonItem = UIBarButtonItem(image: UIImage.refreshButtonIcon(), style: UIBarButtonItem.Style.plain, target: self, action: #selector(reloadOrStop(_:)))
        reloadStopBarButtonItem.tintColor = .white
        navBackBarButtonItem = UIBarButtonItem(image: UIImage.backButtonIcon(), style: UIBarButtonItem.Style.plain, target: self, action: #selector(navBack(_:)))
        navBackBarButtonItem.tintColor = .white
        navForwardBarButtonItem = UIBarButtonItem(image: UIImage.forwardButtonIcon(), style: UIBarButtonItem.Style.plain, target: self, action: #selector(navForward(_:)))
        navForwardBarButtonItem.tintColor = .white
    }

    func reload() {
        if let url = webView.url {
            var request = URLRequest(url: url)
            request.cachePolicy = urlRequest?.cachePolicy ?? .returnCacheDataElseLoad
            webView.load(request)
        }
    }

    @objc func navBack(_ sender: Any?) {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc func navForward(_ sender: Any?) {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    @objc
    func reloadOrStop(_ sender: Any?) {
        if (webView.isLoading) {
            webView.stopLoading()
        }
        else {
            reload()
        }
    }
}

extension WebViewController: WKUIDelegate { }

extension WebViewController : WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (self.webView.title?.count ?? 0) > 0 {
                self.title = self.webView.title
            }
            self.reloadStopBarButtonItem.image = UIImage.refreshButtonIcon()
            self.navBackBarButtonItem.isEnabled = webView.canGoBack
            self.navForwardBarButtonItem.isEnabled = webView.canGoForward
            DispatchQueue.main.after(0.05) { [weak self] in
                self?.webView.layoutSubviews()
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let urlString = navigationAction.request.url?.absoluteString, urlString.hasPrefix("magnet:?") {
            Helper.shared.selectDownloadMethod(for: urlString, andTorrent: urlString, showIn: self)
            decisionHandler(.cancel)
        }
        else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.reloadStopBarButtonItem.image = UIImage.stopButtonIcon()
            self.navBackBarButtonItem.isEnabled = webView.canGoBack
            self.navForwardBarButtonItem.isEnabled = webView.canGoForward
        }
    }
}
