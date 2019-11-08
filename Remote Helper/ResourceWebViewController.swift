//
//  ResourceWebViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 11/8/19.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import SwiftSoup

class ResourceWebViewController: WebViewController {

    var validAddresses: [Link] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let modeItem = AppDelegate.shared.addressesSplitViewController!.displayModeButtonItem
        navigationItem.leftBarButtonItem = modeItem
        navigationItem.leftItemsSupplementBackButton = true

        let parseHTMLBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(fetchHTMLAndParse(_:)))
        additionalBarButtonItems = [parseHTMLBarButtonItem]
    }
}

extension ResourceWebViewController {
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
extension ResourceWebViewController: UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.barButtonItem = navigationItem.rightBarButtonItems?[0]
    }
}

extension ResourceWebViewController {
    @objc
    func fetchHTMLAndParse(_ sender: Any?) {
        webView.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            guard let self = self else { return }
            if error == nil {
                guard let html = result as? String else { return }
                self.processHTML(html)
            }
        }
    }

    func processHTML(_ html: String) {
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
                performSegue(withIdentifier: "showBangumiFromWebPageSegue", sender: nil)
            }
        } catch let error as NSError {
            print("HTML Parse Error: \(error), \(error.userInfo)")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBangumiFromWebPageSegue",
            let vc = segue.destination as? BangumiViewController {
            let bangumi = Bangumi(title: String(format: NSLocalizedString("Found %ld links", comment: "Found %ld links"), validAddresses.count), links: validAddresses)
            vc.bangumi = bangumi
        }
    }
}
