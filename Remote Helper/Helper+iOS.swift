//
//  Helper+iOS.swift
//  Remote Helper
//
//  Created by venj on 7/18/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import Alamofire
import SafariServices
import Reachability
import SwiftEntryKit

enum NoteType {
    case normal
    case warning
    case error

    var color: UIColor {
        switch self {
        case .normal:
            return UIColor(red:0.40, green:0.73, blue:0.16, alpha:1.00)
        case .warning:
            return UIColor(red:0.89, green:0.40, blue:0.00, alpha:1.00)
        case .error:
            return UIColor(red:0.94, green:0.28, blue:0.14, alpha:1.00)
        }
    }
}

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

    func showProcessingNote(withMessage message: String) {
        let style = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 14.0), color: .white, alignment: .center)
        let labelContent = EKProperty.LabelContent(text: message, style: style)

        let contentView = EKProcessingNoteMessageView(with: labelContent, activityIndicator: .white)
        var attributes = EKAttributes.topNote
        attributes.displayDuration = .infinity
        attributes.statusBar = .light
        attributes.scroll = .disabled
        attributes.windowLevel = .statusBar
        attributes.entryInteraction = .absorbTouches
        attributes.name = "Top Note"
        attributes.hapticFeedbackType = .none
        attributes.popBehavior = .animated(animation: .translation)
        attributes.entryBackground = .color(color: UIColor(red:0.42, green:0.44, blue:0.89, alpha:1.00))
        attributes.shadow = .active(with: .init(color: UIColor.init(red: 48.0/255.0, green: 47.0/255.0, blue: 48.0/255.0, alpha: 1.0), opacity: 0.5, radius: 2))

        SwiftEntryKit.display(entry: contentView, using: attributes, presentInsideKeyWindow: true)
    }

    func showNote(withMessage message: String, type: NoteType = .normal) {
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
        attributes.entryBackground = .color(color: type.color)
        attributes.shadow = .active(with: .init(color: UIColor.init(red: 48.0/255.0, green: 47.0/255.0, blue: 48.0/255.0, alpha: 1.0), opacity: 0.5, radius: 2))

        SwiftEntryKit.display(entry: contentView, using: attributes, presentInsideKeyWindow: true)
    }

    func showCellularHUD() -> Bool {
        guard let reachability = self.reachability else { return false }
        if !Configuration.shared.userCellularNetwork && reachability.connection != .wifi {
            DispatchQueue.main.async(execute: { [weak self] in
                guard let `self` = self else { return }
                self.showNote(withMessage: NSLocalizedString("Cellular data is turned off.", comment: "Cellular data is turned off."), type: .warning)
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
            // Not show hud if intelligent torrent download is enabled
            if !Configuration.shared.isIntelligentTorrentDownloadEnabled {
                self.showProcessingNote(withMessage: NSLocalizedString("Searching...", comment: "Searching..."))
            }

            let link = self.kittenSearchPath(withKeyword: keyword)
            let url = URL(string: link)!
            let request = Alamofire.request(url)
            request.responseData { [weak self] response in
                guard let `self` = self else { return }
                guard response.result.isSuccess, let data = response.result.value else {
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.showNote(withMessage: NSLocalizedString("Connection failed.", comment: "Connection failed."), type: .error)
                    }
                    return
                }

                let source = Configuration.shared.torrentKittenSource
                let torrents = KittenTorrent.parse(data: data, source: source)
                if torrents.count == 0 {
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.showNote(withMessage: NSLocalizedString("No torrent found", comment: "No torrent found"), type: .warning)
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
                        SwiftEntryKit.dismiss()
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
                    SwiftEntryKit.dismiss()
                }
            }
        }
        alertController.addAction(searchAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        viewController.present(alertController, animated: true, completion: nil)
    }


    func transmissionDownload(for link: String) {
        if !Configuration.shared.isIntelligentTorrentDownloadEnabled {
            self.showProcessingNote(withMessage: NSLocalizedString("Connecting to Transmission...", comment: "Connecting to Transmission..."))
        }
        parseSessionAndAddTask(link, completionHandler: { [weak self] in
            guard let `self` = self else { return }
            self.showNote(withMessage: NSLocalizedString("Task added.", comment: "Task added."))
        }, errorHandler: { [weak self] in
            guard let `self` = self else { return }
            self.showNote(withMessage: NSLocalizedString("Transmission server error.", comment: "Transmission server error."), type: .error)
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
            self.showNote(withMessage: NSLocalizedString("Mi account not set.", comment: "Mi account not set."), type: .warning)
            return
        }
        MiDownloader(withUsername:Configuration.shared.miAccountUsername, password: Configuration.shared.miAccountPassword, links: links).loginAndFetchDeviceList(progress: { [weak self] (progress) in
            guard let `self` = self else { return }
            switch progress {
            case .prepare:
                self.showProcessingNote(withMessage: NSLocalizedString("Preparing...", comment: "Preparing..."))
            case .login:
                self.showProcessingNote(withMessage: NSLocalizedString("Loging in...", comment: "Loging in..."))
            case .fetchDevice:
                self.showProcessingNote(withMessage: NSLocalizedString("Loading Device...", comment: "Loading Device..."))
            case .download:
                self.showProcessingNote(withMessage: NSLocalizedString("Add download...", comment: "Add download..."))
            }
        }, success: { (success) in
            switch success {
            case .added:
                self.showNote(withMessage: NSLocalizedString("Added!", comment: "Added!"))
            case .duplicate:
                self.showNote(withMessage: NSLocalizedString("Duplicated!", comment: "Duplicated!"), type: .warning)
            case .other(let code):
                self.showNote(withMessage: NSLocalizedString("Added! Code: ", comment: "Added! Code: ") + "\(code)")
            }
        }, error: { [weak self] (error) in
            guard let `self` = self else { return }
            switch error {
            case .capchaError(let link):
                SwiftEntryKit.dismiss()
                DispatchQueue.main.after(0.5, execute: { [weak self] in
                    guard let `self` = self else { return }
                    self.showMiDownload(for: link, inViewController: viewController)
                })
            default:
                let reason = error.localizedDescription
                self.showNote(withMessage: reason, type: .error)
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
