//
//  Helper+iOS.swift
//  Remote Helper
//
//  Created by venj on 7/18/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import PKHUD
import Alamofire
import SafariServices
import TOWebViewController
import Reachability
import SwiftEntryKit

extension Helper {

    var reachability: Reachability? {
        let reach = Reachability()
        try? reach?.startNotifier()
        return reach!
    }

    //MARK: - UI Related Helpers
    func mainThemeColor() -> UIColor {
        return UIColor(red:0.94, green:0.44, blue:0.19, alpha:1)
    }

    func showNote(withMessage message: String) {
        let text = message
        let style = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 14.0), color: .white, alignment: .center)
        let labelContent = EKProperty.LabelContent(text: text, style: style)

        let contentView = EKNoteMessageView(with: labelContent)
        var attributes = EKAttributes.topNote
        attributes.scroll = .disabled
        attributes.windowLevel = .statusBar
        attributes.entryInteraction = .absorbTouches
        attributes.name = "Top Note"
        attributes.hapticFeedbackType = .success
        attributes.popBehavior = .animated(animation: .translation)
        attributes.entryBackground = .color(color: UIColor(red:0.40, green:0.73, blue:0.16, alpha:1.00))
        attributes.shadow = .active(with: .init(color: UIColor.init(red: 48.0/255.0, green: 47.0/255.0, blue: 48.0/255.0, alpha: 1.0), opacity: 0.5, radius: 2))
        attributes.statusBar = .light

        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    func showCellularHUD() -> Bool {
        guard let reachability = self.reachability else { return false }
        if !Configuration.shared.userCellularNetwork && reachability.connection != .wifi {
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                //PKHUD.sharedHUD.showHudWithMessage(NSLocalizedString("Cellular data is turned off.", comment: "Cellular data is turned off."))
                guard let `self` = self else { return }
                self.showNote(withMessage: NSLocalizedString("Cellular data is turned off.", comment: "Cellular data is turned off."))
            })
            return true
        }
        return false
    }

    @objc func dismissMe(_ sender: UIBarButtonItem) {
        AppDelegate.shared.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }

    // Nasty method naming, just for minimum code change
    func showTorrentSearchAlertInViewController(_ viewController:UIViewController?) {
        guard let viewController = viewController else { return } // Just do nothing...
        if (self.showCellularHUD()) { return }
        let source = Configuration.shared.torrentKittenSource
        // Prevent Kitty Search when no server configured.
        if source == .main && !Configuration.shared.hasTorrentServer {
            let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: NSLocalizedString("Search TorrentKitty now requires server support, please change to other search sources in Settings.", comment: "Search TorrentKitty now requires server support, please change to other search sources in Settings."), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel)
            alert.addAction(okAction)
            return
        }
        let title = NSLocalizedString("Search Torrent Kitten", comment: "Search Torrent Kitten")
        let message = NSLocalizedString("Please enter video serial (or anything).\nUsing mirror: ", comment: "Please enter video serial (or anything).\nUsing mirror: ") + source.description
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.keyboardType = .default
            textField.becomeFirstResponder()
        }
        let searchAction = UIAlertAction(title: NSLocalizedString("Search", comment: "Search"), style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            let keyword = alertController.textFields![0].text!
            let hud = PKHUD.sharedHUD
            // Not show hud if intelligent torrent download is enabled
            if !Configuration.shared.isIntelligentTorrentDownloadEnabled { hud.showHUD() }

            let link = self.kittenSearchPath(withKeyword: keyword)
            let url = URL(string: link)!
            let request = Alamofire.request(url)
            request.responseData { [weak self] response in
                guard let `self` = self else { return }
                guard response.result.isSuccess, let data = response.result.value else {
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.showNote(withMessage: NSLocalizedString("Connection failed.", comment: "Connection failed."))
                        //PKHUD.sharedHUD.showHudWithMessage(NSLocalizedString("Connection failed.", comment: "Connection failed."))
                    }
                    return
                }

                let source = Configuration.shared.torrentKittenSource
                let torrents = KittenTorrent.parse(data: data, source: source)
                if torrents.count == 0 {
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.showNote(withMessage: NSLocalizedString("No torrent found", comment: "No torrent found"))
                        //PKHUD.sharedHUD.showHudWithMessage(NSLocalizedString("No torrent found", comment: "No torrent found"))
                    }
                    return
                }

                // Intelligent add torrents
                if Configuration.shared.isIntelligentTorrentDownloadEnabled {
                    let selectedTorrents = torrents.filter { torrent in
                        let lowercasedTitle = torrent.title.lowercased()
                        if torrent.date.timeIntervalSinceNow < 3153600, // torrent older than 1 year
                            lowercasedTitle.contains("mp4"), // MP4 Prefered
                            lowercasedTitle.matches("\\w+-?\\d+"), // Bango pattern
                            (lowercasedTitle.contains(keyword.lowercased()) ||
                                lowercasedTitle.contains(keyword.replacingOccurrences(of: "-", with: "").lowercased())) {
                            return true
                        }
                        return false
                        }
                        .sorted { // Prefers shoter title over newer time.
                            $0.title.count < $1.title.count || $0.date > $1.date
                    }

                    // Download it!
                    if selectedTorrents.count > 0 {
                        self.transmissionDownload(for: selectedTorrents[0].magnet) // Always download latest torrent.
                        return
                    }
                }

                // Show results
                DispatchQueue.main.async {
                    if let tabControl =  UIApplication.shared.keyWindow?.rootViewController as? UITabBarController, let navControl = tabControl.selectedViewController as? UINavigationController, let searchControl = navControl.topViewController as? VPSearchResultController {
                        searchControl.torrents = torrents
                        searchControl.keyword = keyword
                        searchControl.tableView.reloadData()
                        hud.hide()
                        return
                    }
                    let searchResultController = VPSearchResultController()
                    searchResultController.torrents = torrents
                    searchResultController.keyword = keyword
                    if let navigationController = viewController as? UINavigationController {
                        navigationController.pushViewController(searchResultController, animated: true)
                    }
                    else if let tabbarController = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController as? UITabBarController, let navigationController = tabbarController.selectedViewController as? UINavigationController {
                        navigationController.pushViewController(searchResultController, animated: true)
                    }
                    else {
                        let searchResultNavigationController = UINavigationController(rootViewController: searchResultController)
                        searchResultController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target:self, action: #selector(Helper.dismissMe(_:)))
                        viewController.present(searchResultNavigationController, animated: true, completion: nil)
                    }
                    hud.hide()
                }
            }
        }
        alertController.addAction(searchAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.view.tintColor = Helper.shared.mainThemeColor()
        viewController.present(alertController, animated: true, completion: nil)
    }


    func transmissionDownload(for link: String) {
        if !Configuration.shared.isIntelligentTorrentDownloadEnabled { PKHUD.sharedHUD.showHUD() }
        parseSessionAndAddTask(link, completionHandler: { [weak self] in
            guard let `self` = self else { return }
            self.showNote(withMessage: NSLocalizedString("Task added.", comment: "Task added."))
            //PKHUD.sharedHUD.showHudWithMessage(NSLocalizedString("Task added.", comment: "Task added."))
        }, errorHandler: { [weak self] in
            guard let `self` = self else { return }
            self.showNote(withMessage: NSLocalizedString("Transmission server error.", comment: "Transmission server error."))
            //PKHUD.sharedHUD.showHudWithMessage(NSLocalizedString("Transmission server error.", comment: "Transmission server error."))
        })
    }

    var canStartMiDownload: Bool {
        return !(Configuration.shared.miAccountUsername.isEmpty || Configuration.shared.miAccountPassword.isEmpty)
    }

    func miDownloadForLink(_ link: String, fallbackIn viewController: UIViewController) {
        miDownloadForLinks([link], fallbackIn: viewController)
    }

    func miDownloadForLinks(_ links: [String], fallbackIn viewController: UIViewController) {
        guard canStartMiDownload else {
            self.showNote(withMessage: NSLocalizedString("Mi account not set.", comment: "Mi account not set."))
            //PKHUD.sharedHUD.showHudWithMessage(NSLocalizedString("Mi account not set.", comment: "Mi account not set."))
            return
        }
        let hud = PKHUD.sharedHUD.showHUD()
        MiDownloader(withUsername:Configuration.shared.miAccountUsername, password: Configuration.shared.miAccountPassword, links: links).loginAndFetchDeviceList(progress: { (progress) in
            switch progress {
            case .prepare:
                hud.setMessage(NSLocalizedString("Preparing...", comment: "Preparing..."))
            case .login:
                hud.setMessage(NSLocalizedString("Loging in...", comment: "Loging in..."))
            case .fetchDevice:
                hud.setMessage(NSLocalizedString("Loading Device...", comment: "Loading Device..."))
            case .download:
                hud.setMessage(NSLocalizedString("Add download...", comment: "Add download..."))
            }
        }, success: { (success) in
            switch success {
            case .added:
                hud.setMessage(NSLocalizedString("Added!", comment: "Added!"))
            case .duplicate:
                hud.setMessage(NSLocalizedString("Duplicated!", comment: "Duplicated!"))
            case .other(let code):
                hud.setMessage(NSLocalizedString("Added! Code: ", comment: "Added! Code: ") + "\(code)")
            }
            hud.hide(afterDelay: 1.0)
        }, error: { [weak self] (error) in
            hud.hide()
            guard let `self` = self else { return }
            switch error {
            case .capchaError(let link):
                PKHUD.sharedHUD.hide()
                DispatchQueue.main.after(0.5, execute: { [weak self] in
                    guard let `self` = self else { return }
                    self.showMiDownload(for: link, inViewController: viewController)
                })
            default:
                let reason = error.localizedDescription
                self.showNote(withMessage: reason)
                //PKHUD.sharedHUD.showHudWithMessage(reason)
            }
        })
    }

    func parseSessionAndAddTask(_ magnet:String, completionHandler:(() -> Void)? = nil, errorHandler:(() -> Void)? = nil) {
        let params = ["method" : "session-get"]
        let HTTPHeaders = ["X-Transmission-Session-Id" : sessionHeader]
        let request = Alamofire.request(Configuration.shared.transmissionRPCAddress(), method: .post, parameters: params, encoding: JSONEncoding(options: []),headers: HTTPHeaders)
        request.authenticate(user: Configuration.shared.transmissionUsername, password: Configuration.shared.transmissionPassword).responseJSON { [weak self] response in
            guard let `self` = self else { return }
            if response.result.isSuccess {
                let responseObject = response.result.value as! [String:Any]
                let result = responseObject["result"] as! String
                if result == "success" {
                    self.downloadPath = (responseObject["arguments"] as! [String: Any])["download-dir"] as! String
                    self.downloadTask(magnet, toDir: self.downloadPath, completionHandler: completionHandler, errorHandler: errorHandler)
                }
                else {
                    errorHandler?()
                }
            }
            else {
                if response.response?.statusCode == 409 {
                    self.sessionHeader = response.response!.allHeaderFields["X-Transmission-Session-Id"] as! String
                    let params = ["method" : "session-get"]
                    let HTTPHeaders = ["X-Transmission-Session-Id" : self.sessionHeader]
                    let request = Alamofire.request(Configuration.shared.transmissionRPCAddress(), method: .post, parameters: params, encoding: JSONEncoding(options: []),headers: HTTPHeaders)
                    request.authenticate(user: Configuration.shared.transmissionUsername, password: Configuration.shared.transmissionPassword).responseJSON { [weak self] response in
                        guard let `self` = self else { return }
                        if response.result.isSuccess {
                            let responseObject = response.result.value as! [String:Any]
                            let result = responseObject["result"] as! String
                            if result == "success" {
                                self.downloadPath = (responseObject["arguments"] as! [String: Any])["download-dir"] as! String
                                self.downloadTask(magnet, toDir: self.downloadPath, completionHandler: completionHandler, errorHandler: errorHandler)
                            }
                            else {
                                errorHandler?()
                            }
                        }
                        else {
                            let alertController = UIAlertController(title: NSLocalizedString("Error", comment:"Error"), message: NSLocalizedString("Unkown error.", comment: "Unknow error."), preferredStyle: .alert)
                            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
                            alertController.addAction(cancelAction)
                            alertController.view.tintColor = Helper.shared.mainThemeColor()
                            AppDelegate.shared.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
                else {
                    errorHandler?()
                }
            }
        }
    }

    func showMiDownload(for link: String, inViewController viewController: UIViewController) {
        guard let miURL = URL(string:(link)) else { return }
        if #available(iOS 9.0, *) {
            let sfVC = SFSafariViewController(url: miURL)
            sfVC.title = NSLocalizedString("Mi Remote", comment: "Mi Remote")
            sfVC.modalPresentationStyle = .formSheet
            sfVC.modalTransitionStyle = .coverVertical
            viewController.navigationController?.present(sfVC, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
            let webView = TOWebViewController(url: miURL)!
            webView.title = NSLocalizedString("Mi Remote", comment: "Mi Remote")
            webView.modalPresentationStyle = .formSheet
            webView.modalTransitionStyle = .coverVertical
            viewController.navigationController?.present(webView, animated: true, completion: nil)
        }
    }
}
