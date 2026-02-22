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

    var containerView: UIView!
    var webView: WKWebView!
    var bottomToolbarEffectView: UIVisualEffectView!
    var bottomToolbarContentView: UIView!
    var bottomButtonsStackView: UIStackView!
    var compactBackButton: UIButton!
    var compactForwardButton: UIButton!
    var compactReloadStopButton: UIButton!
    var bottomToolbarHeightConstraint: NSLayoutConstraint!
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
        containerView = UIView(frame: .zero)
        containerView.backgroundColor = .systemBackground

        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        bottomToolbarEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        bottomToolbarEffectView.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbarEffectView.isHidden = true

        bottomToolbarContentView = UIView(frame: .zero)
        bottomToolbarContentView.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbarContentView.backgroundColor = .clear

        compactBackButton = makeCompactToolbarButton(systemImage: "chevron.backward")
        compactForwardButton = makeCompactToolbarButton(systemImage: "chevron.forward")
        compactReloadStopButton = makeCompactToolbarButton(systemImage: "arrow.clockwise")

        compactBackButton.addTarget(self, action: #selector(navBack(_:)), for: .touchUpInside)
        compactForwardButton.addTarget(self, action: #selector(navForward(_:)), for: .touchUpInside)
        compactReloadStopButton.addTarget(self, action: #selector(reloadOrStop(_:)), for: .touchUpInside)

        bottomButtonsStackView = UIStackView(arrangedSubviews: [compactBackButton, compactForwardButton, compactReloadStopButton])
        bottomButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomButtonsStackView.axis = .horizontal
        bottomButtonsStackView.alignment = .center
        bottomButtonsStackView.distribution = .fillEqually
        bottomButtonsStackView.spacing = 12.0

        containerView.addSubview(webView)
        containerView.addSubview(bottomToolbarEffectView)
        bottomToolbarEffectView.contentView.addSubview(bottomToolbarContentView)
        bottomToolbarContentView.addSubview(bottomButtonsStackView)

        bottomToolbarHeightConstraint = bottomToolbarEffectView.heightAnchor.constraint(equalToConstant: 0.0)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomToolbarEffectView.topAnchor),

            bottomToolbarEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomToolbarEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomToolbarEffectView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            bottomToolbarHeightConstraint,

            bottomToolbarContentView.leadingAnchor.constraint(equalTo: bottomToolbarEffectView.contentView.leadingAnchor),
            bottomToolbarContentView.trailingAnchor.constraint(equalTo: bottomToolbarEffectView.contentView.trailingAnchor),
            bottomToolbarContentView.topAnchor.constraint(equalTo: bottomToolbarEffectView.contentView.topAnchor),
            bottomToolbarContentView.bottomAnchor.constraint(equalTo: bottomToolbarEffectView.contentView.bottomAnchor),

            bottomButtonsStackView.centerXAnchor.constraint(equalTo: bottomToolbarContentView.centerXAnchor),
            bottomButtonsStackView.centerYAnchor.constraint(equalTo: bottomToolbarContentView.centerYAnchor),
            bottomButtonsStackView.heightAnchor.constraint(equalToConstant: 36.0)
        ])

        view = containerView
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
        navigationItem.setHidesBackButton(false, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if view.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            setupBarButtonItems()
        }
    }

    func setupBarButtonItems() {
        navigationController?.setToolbarHidden(true, animated: false)

        if view.traitCollection.horizontalSizeClass == .compact {
            bottomToolbarHeightConstraint.constant = 56.0
            bottomToolbarEffectView.isHidden = false
            updateCompactToolbarButtonStates()
            navigationItem.rightBarButtonItems = additionalBarButtonItems
        }
        else {
            bottomToolbarHeightConstraint.constant = 0.0
            bottomToolbarEffectView.isHidden = true
            navigationItem.rightBarButtonItems = additionalBarButtonItems + [reloadStopBarButtonItem, navForwardBarButtonItem, navBackBarButtonItem]
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView?.stopLoading()
        bottomToolbarHeightConstraint.constant = 0.0
        bottomToolbarEffectView.isHidden = true
        navigationItem.setHidesBackButton(true, animated: animated)
        navigationItem.rightBarButtonItems = nil
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func configureBarButtonItems() {
        reloadStopBarButtonItem = UIBarButtonItem(image: navigationBarSymbol(named: "arrow.clockwise"), style: .plain, target: self, action: #selector(reloadOrStop(_:)))
        navBackBarButtonItem = UIBarButtonItem(image: navigationBarSymbol(named: "chevron.backward"), style: .plain, target: self, action: #selector(navBack(_:)))
        navForwardBarButtonItem = UIBarButtonItem(image: navigationBarSymbol(named: "chevron.forward"), style: .plain, target: self, action: #selector(navForward(_:)))
        navBackBarButtonItem.isEnabled = false
        navForwardBarButtonItem.isEnabled = false
        updateCompactToolbarButtonStates()
    }

    private func navigationBarSymbol(named name: String) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 17.0, weight: .semibold, scale: .medium)
        return UIImage(systemName: name, withConfiguration: configuration)
    }

    private func makeCompactToolbarButton(systemImage: String) -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.baseBackgroundColor = UIColor.tertiarySystemBackground
        configuration.baseForegroundColor = .label
        configuration.cornerStyle = .capsule
        configuration.image = UIImage(systemName: systemImage)
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        let button = UIButton(type: .system)
        button.configuration = configuration
        return button
    }

    private func updateCompactReloadStopIcon() {
        let symbolName = webView?.isLoading == true ? "xmark" : "arrow.clockwise"
        compactReloadStopButton.configuration?.image = UIImage(systemName: symbolName)
    }

    private func updateCompactToolbarButtonStates() {
        compactBackButton.isEnabled = webView?.canGoBack == true
        compactForwardButton.isEnabled = webView?.canGoForward == true
        updateCompactReloadStopIcon()
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
            reloadStopBarButtonItem.image = navigationBarSymbol(named: "arrow.clockwise")
            updateCompactToolbarButtonStates()
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
            self.reloadStopBarButtonItem.image = self.navigationBarSymbol(named: "arrow.clockwise")
            self.navBackBarButtonItem.isEnabled = webView.canGoBack
            self.navForwardBarButtonItem.isEnabled = webView.canGoForward
            self.updateCompactToolbarButtonStates()
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
            self.reloadStopBarButtonItem.image = self.navigationBarSymbol(named: "xmark")
            self.navBackBarButtonItem.isEnabled = webView.canGoBack
            self.navForwardBarButtonItem.isEnabled = webView.canGoForward
            self.updateCompactToolbarButtonStates()
        }
    }
}
