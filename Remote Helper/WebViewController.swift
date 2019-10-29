//
//  WebViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 9/30/19.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import WebKit
import SwiftSoup

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
    var parseHTMLBarButtonItem: UIBarButtonItem!

    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }

    convenience init(urlString: String) {
        self.init(nibName: nil, bundle: nil)
        self.urlString = urlString
        self.url = URL(string: urlString)
        if let url = self.url {
            self.urlRequest = URLRequest(url: url)
        }
    }

    convenience init(url: URL) {
        self.init(nibName: nil, bundle: nil)
        self.urlString = url.absoluteString
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
            navigationItem.rightBarButtonItems = additionalBarButtonItems + [parseHTMLBarButtonItem]
        }
        else {
            navigationController?.toolbar.setItems([], animated: false)
            navigationController?.setToolbarHidden(true, animated: false)
            navigationItem.rightBarButtonItems = additionalBarButtonItems + [parseHTMLBarButtonItem, reloadStopBarButtonItem, navForwardBarButtonItem, navBackBarButtonItem]
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView?.stopLoading()
        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController?.setToolbarHidden(true, animated: false)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func configureBarButtonItems() {
        let modeItem = AppDelegate.shared.addressesSplitViewController!.displayModeButtonItem
        navigationItem.leftBarButtonItem = modeItem
        navigationItem.leftItemsSupplementBackButton = true
        reloadStopBarButtonItem = UIBarButtonItem(image: UIImage.stopButtonIcon(), style: UIBarButtonItem.Style.plain, target: self, action: #selector(reloadOrStop(_:)))
        navBackBarButtonItem = UIBarButtonItem(image: UIImage.backButtonIcon(), style: UIBarButtonItem.Style.plain, target: self, action: #selector(navBack(_:)))
        navForwardBarButtonItem = UIBarButtonItem(image: UIImage.forwardButtonIcon(), style: UIBarButtonItem.Style.plain, target: self, action: #selector(navForward(_:)))
        parseHTMLBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(fetchHTMLAndParse(_:)))
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

    @objc
    func goBack(_ sender: Any?) {
        if webView.canGoBack {
            webView.goBack()
        }
        else {
            if let _ = presentingViewController {
                Helper.shared.dismissMe(sender)
            }
            else {
                navigationController?.popViewController(animated: true)
            }
        }
    }

}

extension WebViewController: WKUIDelegate { }

extension WebViewController : WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(webView.isLoading ? "loading" : "loaded")
        print("web page loaded, title: (\(webView.title ?? "nil"))")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (self.webView.title?.count ?? 0) > 0 {
                self.title = self.webView.title
            }
            self.reloadStopBarButtonItem.image = UIImage.refreshButtonIcon()
            self.navBackBarButtonItem.isEnabled = webView.canGoBack
            self.navForwardBarButtonItem.isEnabled = webView.canGoForward
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

extension WebViewController {
    @available(iOS 9.0, *)
    override open var previewActionItems: [UIPreviewActionItem] {
        get {
            let deleteItem = UIPreviewAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (action, vc)  in
                if let webContentViewController = AppDelegate.shared.fileListViewController {
                    webContentViewController.deletePreviewingCell()
                }
            })
            return [deleteItem]
        }
    }
}

//MARK: - UIPopoverPresentationControllerDelegate
extension WebViewController: UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.barButtonItem = navigationItem.rightBarButtonItems?[0]
    }
}

extension WebViewController {
    @IBAction func fetchHTMLAndParse(_ sender: Any?) {
        webView.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            guard let self = self else { return }
            if error == nil {
                guard let html = result as? String else { return }
                self.processHTML(html)
            }
        }
    }

    func processHTML(_ html: String) {
        var validAddresses: [Link] = []
        do {
            let doc = try SwiftSoup.parse(html)
            let links: [Link] = try doc.select("a").compactMap { e in
                let href = try e.attr("href")
                let loweredLink = href.lowercased()
                if loweredLink.hasPrefix("magnet:?")
                    || loweredLink.hasPrefix("ed2k://")
                    || loweredLink.hasPrefix("thunder://")
                    || loweredLink.hasPrefix("ftp://")
                    || loweredLink.hasPrefix("ftps://")
                    || loweredLink.hasPrefix("qqdl://")
                    || loweredLink.hasPrefix("flashget://") {
                    return Link(href)
                }
                else {
                    return nil
                }
            }

            validAddresses = links

            if validAddresses.count == 0 {
                Helper.shared.showNote(withMessage: NSLocalizedString("No downloadable link.", comment: "No downloadable link."), type:.warning)
            }
            else {
                let linksViewController = BangumiViewController()
                let bangumi = Bangumi(title: String(format: NSLocalizedString("Found %ld links", comment: "Found %ld links"), validAddresses.count), links: validAddresses)
                linksViewController.bangumi = bangumi
                navigationController?.pushViewController(linksViewController, animated: true)
            }
        } catch let error as NSError {
            print("HTML Parse Error: \(error), \(error.userInfo)")
        }
    }
}
