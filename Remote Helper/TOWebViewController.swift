//
//  TOWebViewController.swift
//  Remote Helper
//
//  Created by venj on 10/20/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit

class TWOWebLoadingView: UIView {
    override func tintColorDidChange() {
        backgroundColor = tintColor
    }
}

class TWOWebViewController: UIViewController, UIWebViewDelegate, UIPopoverPresentationControllerDelegate, CAAnimationDelegate {

    struct webViewState {
        var frameSize: CGSize
        var contentSize: CGSize
        var contentOffset: CGSize
        var zoomScale: CGFloat
        var minimumZoomScale: CGFloat
        var maximumZoomScale: CGFloat
        var topEdgeInset: CGFloat
        var bottomEdgeInset: CGFloat
    }

    struct loadingProgressState {
        var loadingCount: Int
        var maxLoadCount: Int
        var interactive: Bool
        var loadingProgress: Float
    }

    var url: URL? = nil {
        didSet {
            if let url = url {
                let request = URLRequest(url: url)
                urlRequest = request
                if webView.isLoading {
                    webView.stopLoading()
                }
                webView.loadRequest(request)
            }
            else {
                urlRequest = nil
            }
        }
    }
    var urlRequest: URLRequest? = nil
    lazy var webView: UIWebView = UIWebView(frame: .zero)
    var showLoadingBar: Bool = true
    var showUrlWhileLoading: Bool = true
    var loadingBarTintColor: UIColor? = nil {
        didSet {
            if let color = loadingBarTintColor {
                loadingBarView.backgroundColor = color
                loadingBarView.tintColor = color
            }
        }
    }
    var navigationButtonsHidden: Bool = false {
        didSet {
            // FIXME: Setup navigation bar buttons
            if navigationButtonsHidden {
                if isiPad {
                    navigationItem.rightBarButtonItem = nil
                }
                else {
                    navigationController?.toolbarItems = []
                    navigationController?.isToolbarHidden = true
                }
            }
            else {
                if isiPad {
                    navigationItem.rightBarButtonItems = []
                }
                else {
                    self.toolbarItems = []
                }
            }
        }
    }
    var showActionButtons: Bool = true
    var showDoneButton: Bool = true
    var doneButtonTitle: String? = nil
    var showPageTitles: Bool = true
    var disableContextualPopupMenu: Bool = true
    var hideWebViewBoundaries: Bool = true
    var modelCompletionHandler: (() -> Void)?
    var shouldStartLoadRequestHandler: ((URLRequest, UIWebView.NavigationType) -> Bool)?
    var buttonTintColor: UIColor? = nil
    var showAdditionalBarButtonItems: Bool = true
    var additionalBarButtonItems: [UIBarButtonItem] = []
    var isPeeking: Bool = false

    private var isiPad: Bool {
        get {
            return UI_USER_INTERFACE_IDIOM() == .pad
        }
    }

    var beingPresentedModally: Bool {
        get {
            if navigationController != nil && navigationController?.presentingViewController != nil {
                return navigationController!.viewControllers.firstIndex(of: self) == 0
            }
            else if self.isPeeking {
                return false
            }
            else {
                return self.presentingViewController != nil
            }
        }
    }
    var onTopOfNavigationControllerStack: Bool {
        get {
            guard let navigationController = navigationController else { return false }

            if let index = navigationController.viewControllers.firstIndex(of: self), index > 0 {
                return true
            }

            return false
        }
    }
    var navigationBar: UINavigationBar? {
        get {
            return navigationController?.navigationBar
        }
    }
    var toolbar: UIToolbar? {
        get {
            return isiPad ? nil : navigationController?.toolbar
        }
    }

    private var loadingBarView: TWOWebLoadingView = TWOWebLoadingView(frame: .zero)
    private var webViewRotationSnapshop: UIImageView? = nil
    private var gradientLayer: CAGradientLayer? = nil

    private var backButton: UIBarButtonItem {
        get {
            return UIBarButtonItem(image: UIImage.backButtonIcon(), style: .plain, target: self, action: #selector(backButtonTapped(_:)))
        }
    }
    private var forwardButton: UIBarButtonItem {
        get {
            return UIBarButtonItem(image: UIImage.forwardButtonIcon(), style: .plain, target: self, action: #selector(forwardButtonTapped(_:)))
        }
    }
    private var reloadButton: UIBarButtonItem {
        get {
            return UIBarButtonItem(image: UIImage.forwardButtonIcon(), style: .plain, target: self, action: #selector(reloadStopButtonTapped(_:)))
        }
    }
    private var actionButton: UIBarButtonItem {
        get {
            return UIBarButtonItem(image: UIImage.actionButtonIcon(), style: .plain, target: self, action: #selector(actionButtonTapped(_:)))
        }
    }
    private var blankBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    private var buttonWidth: CGFloat {
        get {
            return 31.0
        }
    }
    private var buttonSpacing: CGFloat {
        get {
            return isiPad ? 20.0 : 40.0
        }
    }

    private var reloadIcon: UIImage {
        get {
            return UIImage.refreshButtonIcon()
        }
    }
    private var stopIcon: UIImage {
        get {
            return UIImage.stopButtonIcon()
        }
    }

    private var buttonThemeAttributes: [String: Any] = [:]

    private var hideToolbarOnClose: Bool = false
    private var hideNavBarOnClose: Bool = false

    private var customBackButtonItem: UIBarButtonItem {
        get {
            return UIBarButtonItem(image: UIImage.backButtonIcon(), style: .plain, target: self, action: #selector(goBack(_:)))
        }
    }
    private var closeButtonItem: UIBarButtonItem {
        get {
            return UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(close(_:)))
        }
    }

    private var activityViewController: UIActivityViewController? = nil

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    init(url: URL) {
        super.init(nibName: nil, bundle: nil)
        self.url = url.cleaned
        setup()
    }

    init(urlString: String) {
        super.init(nibName: nil, bundle: nil)
        if let url = URL(string: urlString) {
            self.url = url.cleaned
        }
        setup()
    }

    func setup() {
        modalPresentationStyle = .fullScreen
    }

    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = hideWebViewBoundaries ? .white : UIColor(red: 0.741, green: 0.741, blue: 0.76, alpha: 1.0)
        view.isOpaque = true
        view.clipsToBounds = true
        self.view = view

        webView.frame = self.view.bounds
        webView.delegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = .clear
        webView.scalesPageToFit = true
        webView.contentMode = .redraw
        webView.isOpaque = true
        self.view.addSubview(webView)

        let y = webView.scrollView.contentOffset.y
        loadingBarView.frame = CGRect(x: 0.0, y: y, width: self.view.frame.width, height: 2.0)
        loadingBarView.autoresizingMask = [.flexibleWidth]

        if let loadingBarTintColor = loadingBarTintColor {
            loadingBarView.tintColor = loadingBarTintColor
            loadingBarView.backgroundColor = loadingBarTintColor
        }
        else {
            if let color = navigationController?.view.window?.tintColor {
                loadingBarView.backgroundColor = color
            }
            else if let color = view.window?.tintColor {
                loadingBarView.backgroundColor = color
            }
            else {
                loadingBarView.backgroundColor = UIColor(red: 0.0, green: 110.0, blue: 1.0, alpha: 1.0)
            }
        }

    }

    //MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = navigationController {
            hideToolbarOnClose = navigationController.isToolbarHidden
            hideNavBarOnClose = navigationController.navigationBar.isHidden
        }

        if hideWebViewBoundaries {
            gradientLayer?.isHidden = true
        }

        let defaultBarButtonItems = [backButton, forwardButton, reloadButton, actionButton]

        if isiPad {
            if showAdditionalBarButtonItems && additionalBarButtonItems.count > 0 {
                navigationItem.rightBarButtonItems = defaultBarButtonItems + additionalBarButtonItems
            }
            else {
                navigationItem.rightBarButtonItems = defaultBarButtonItems
            }
        }
        else {
            if showAdditionalBarButtonItems && additionalBarButtonItems.count > 0 {
                navigationItem.rightBarButtonItems = additionalBarButtonItems
            }
            toolbarItems = [blankBarButtonItem] + defaultBarButtonItems + [blankBarButtonItem]
        }

        if showDoneButton, beingPresentedModally, !onTopOfNavigationControllerStack {
            let doneButton: UIBarButtonItem
            if let doneButtonTitle = doneButtonTitle, !doneButtonTitle.isEmpty {
                doneButton = UIBarButtonItem(title: doneButtonTitle, style: .done, target: self, action: #selector(doneButtonTapped(_:)))
            }
            else {
                doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(_:)))
            }

            if isiPad {
                navigationItem.leftBarButtonItem = doneButton
            }
            else {
                navigationItem.rightBarButtonItem = doneButton
            }
        }

        updateLeftBarButtonItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navigationController = navigationController {
            if isiPad {
                navigationController.setNavigationBarHidden(false, animated: animated)
                navigationController.setToolbarHidden(true, animated: animated)
            }
            else {
                if beingPresentedModally {
                    navigationController.isToolbarHidden = navigationButtonsHidden
                }
                else {
                    navigationController.setToolbarHidden(navigationButtonsHidden, animated: animated)
                    navigationController.setNavigationBarHidden(false, animated: animated)
                }
            }
        }

        gradientLayer?.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let urlRequest = urlRequest {
            webView.loadRequest(urlRequest)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !beingPresentedModally {
            navigationController?.setToolbarHidden(hideToolbarOnClose, animated: animated)
            navigationController?.setNavigationBarHidden(hideNavBarOnClose, animated: animated)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    override var shouldAutorotate: Bool {
        get {
            return webViewRotationSnapshop == nil
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .default
        }
    }

    //MARK: - Helpers
    func refreshButtonState() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        if webView.isLoading {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            reloadButton.image = self.stopIcon
        }
        else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            reloadButton.image = self.reloadIcon
        }
    }

    func updateLeftBarButtonItems() {
        if webView.canGoBack {
            navigationItem.leftBarButtonItems = [customBackButtonItem, closeButtonItem]
        }
        else {
            navigationItem.leftBarButtonItem = customBackButtonItem
        }
    }

    //MARK: - Actions
    @objc
    func close(_ sender: Any) {
        if beingPresentedModally {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
        else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc
    func goBack(_ sender: Any) {
        if webView.canGoBack {
            webView.goBack()
        }
        else {
            close(sender)
        }
    }

    @objc
    func backButtonTapped(_ sender: Any) {
        webView.goBack()
        refreshButtonState()
    }

    @objc
    func forwardButtonTapped(_ sender: Any) {
        webView.goForward()
        refreshButtonState()
    }

    @objc
    func reloadStopButtonTapped(_ sender: Any) {
        webView.stopLoading()

        if webView.isLoading {
            self.loadingBarView.alpha = 0.0
        }
        else {
            if webView.request?.url?.absoluteString.count == 0, let urlRequest = urlRequest {
                webView.loadRequest(urlRequest)
            }
            else {
                webView.reload()
            }
        }
        refreshButtonState()
    }

    @objc
    func doneButtonTapped(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc
    func actionButtonTapped(_ sender: Any) {
        guard let url = url else { return }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        self.activityViewController = activityViewController
        activityViewController.popoverPresentationController?.delegate = self
        present(activityViewController, animated: true, completion: nil)
    }

    // MARK: Popover Presentation Controller Delegate
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.barButtonItem = actionButton
    }
}

extension URL {
    var cleaned: URL {
        get {
            return (scheme ?? "").count == 0 ? URL(string: "http://\(absoluteString)")! : self
        }
    }
}
