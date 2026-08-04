//
//  XunleiWebViewController.swift
//  Remote Helper
//

import UIKit

final class XunleiWebViewController: WebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let backItem = UIBarButtonItem(image: UIImage.backButtonIcon(), style: .plain, target: self, action: #selector(goBack(_:)))
        navigationItem.leftBarButtonItem = backItem
        additionalBarButtonItems = [
            UIBarButtonItem(title: NSLocalizedString("Close", comment: "Close"), style: .plain, target: self, action: #selector(closeTapped))
        ]
    }

    @objc
    private func goBack(_ sender: Any?) {
        if webView.canGoBack {
            webView.goBack()
        } else {
            closeTapped()
        }
    }

    @objc
    private func closeTapped() {
        syncCookiesAndClose()
    }

    private func syncCookiesAndClose() {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.presentingViewController != nil || self.navigationController?.presentingViewController != nil {
                    self.dismiss(animated: true)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
