//
//  Helper.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import Alamofire
import PKHUD
import ReachabilitySwift

@objc
open class Helper : NSObject {
    open static let defaultHelper = Helper()

    fileprivate var sessionHeader: String = ""
    fileprivate var downloadPath: String = ""
    var reachability: Reachability? = {
        let reach = Reachability()
        try? reach?.startNotifier()
        return reach!
    }()

    //MARK: - Properties
    var useSSL:Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: RequestUseSSL) == nil {
            defaults.set(true, forKey: RequestUseSSL)
            defaults.synchronize()
            return true
        }
        else {
            return defaults.bool(forKey: RequestUseSSL)
        }
    }

    var SSL_ADD_S:String {
        return self.useSSL ? "s" : ""
    }

    var usernameAndPassword:(String, String) {
        let defaults = UserDefaults.standard
        let username = defaults.object(forKey: TransmissionUserNameKey) as? String
        let password = defaults.object(forKey: TransmissionPasswordKey) as? String
        if username != nil && password != nil {
            return (username!, password!)
        }
        else {
            return ("username", "password")
        }
    }

    var xunleiUsernameAndPassword:[String] {
        let defaults = UserDefaults.standard
        let username = defaults.object(forKey: XunleiUserNameKey) as? String
        let password = defaults.object(forKey: XunleiPasswordKey) as? String
        if username != nil && password != nil {
            return [username!, password!]
        }
        else {
            return ["username", "password"]
        }
    }

    var customUserAgent: String? {
        let defaults = UserDefaults.standard
        guard let ua = defaults.string(forKey: CustomRequestUserAgent) else { return nil }
        return ua
    }

    var userCellularNetwork: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: RequestUseCellularNetwork) == nil {
            defaults.set(true, forKey: RequestUseCellularNetwork)
            defaults.synchronize()
            return true
        }
        else {
            return defaults.bool(forKey: RequestUseCellularNetwork)
        }
    }

    //MARK: - Link Helpers
    func torrentsListPath() -> String {
        return "http\(self.SSL_ADD_S)://\(self.baseLink())/torrents";
    }

    func baseLink() -> String {
        let defaults = UserDefaults.standard
        var host = defaults.string(forKey: ServerHostKey)
        if host == nil { host = "192.168.1.1" }
        var port = defaults.string(forKey: ServerPortKey)
        if port == nil { port = "80" }
        var subPath = defaults.string(forKey: ServerPathKey)
        if subPath == nil || subPath == "/" {
            subPath = ""
        }
        else {
            if subPath!.substring(to: subPath!.characters.index(subPath!.startIndex, offsetBy: 1)) != "/" {
                subPath = "/\(subPath)"
            }
            let lastCharIndex = subPath!.characters.index(subPath!.endIndex, offsetBy: -1)
            if subPath?.substring(from: lastCharIndex) == "/" {
                subPath = subPath!.substring(to: lastCharIndex)
            }
        }
        return "\(host!):\(port!)\(subPath!)"
    }

    func fileLink(withPath path:String!) -> String {
        let defaults = UserDefaults.standard
        var host = defaults.string(forKey: ServerHostKey)
        if host == nil { host = "192.168.1.1" }
        var port = defaults.string(forKey: ServerPortKey)
        if port == nil { port = "80" }
        var p = path
        if p == "" {
            p = "/"
        }
        else if (p?.substring(to: (p?.index((p?.startIndex)!, offsetBy: 1))!) != "/") {
            p = "/\(p)"
        }
        return "http\(self.SSL_ADD_S)://\(host!):\(port!)\(p!)"
    }

    func transmissionServerAddress(withUserNameAndPassword withUnP:Bool = true) -> String {
        let defaults = UserDefaults.standard
        var address: String
        if let addr = defaults.string(forKey: TransmissionAddressKey) {
            address = addr
        }
        else {
            address = "127.0.0.1:9091"
        }
        let userpass = self.usernameAndPassword
        if userpass.0.characters.count > 0 && userpass.1.characters.count > 0 && withUnP {
            return "http://\(userpass.0):\(userpass.1)@\(address)"
        }
        else {
            return "http://\(address)"
        }
    }

    func transmissionRPCAddress() -> String {
        return self.transmissionServerAddress(withUserNameAndPassword: false).vc_stringByAppendingPathComponents(["transmission", "rpc"])
    }

    func dbSearchPath(withKeyword keyword: String) -> String {
        let kw = keyword.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
        let escapedKeyword = kw == nil ? "" : kw!
        return "http\(self.SSL_ADD_S)://\(self.baseLink())/db_search?keyword=\(escapedKeyword)"
    }

    func searchPath(withKeyword keyword: String) -> String {
        return "http\(self.SSL_ADD_S)://\(self.baseLink())/search/\(keyword)"
    }
    
    func addTorrent(withName name: String, async: Bool) -> String {
        return "http\(self.SSL_ADD_S)://\(self.baseLink())/lx/\(name)/\(async ? 1 : 0)"
    }

    func hashTorrent(withName name: String) -> String{
        return "http\(self.SSL_ADD_S)://\(self.baseLink())/hash/\(name)"
    }

    //MARK: - Local Files and ImageCache Helpers
    func documentsDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentationDirectory, .userDomainMask, true).first!
    }
    
    func freeDiskSpace() -> Int {
        guard let dictionary = try? FileManager.default.attributesOfFileSystem(forPath: self.documentsDirectory()) else { return 0 }
        let freeFileSystemSizeInBytes = dictionary[FileAttributeKey.systemFreeSize] as! Int
        return freeFileSystemSizeInBytes
    }

    func localFileSize() -> Int {
        var size = 0
        let documentsDirectory = self.documentsDirectory()
        guard let fileEnumerator = FileManager.default.enumerator(atPath: documentsDirectory) else { return 0 }
        for fileName in fileEnumerator {
            let filePath = documentsDirectory.vc_stringByAppendingPathComponent(fileName as! String)
            guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: filePath) else { continue }
            size += (attrs[FileAttributeKey.size] as! Int)
        }
        return size
    }

    func fileToDownload(withPath path: String) -> String {
        return self.documentsDirectory().vc_stringByAppendingPathComponent(path.vc_lastPathComponent())
    }

    func fileSizeString(withInteger integer: Int) -> String {
        return integer.fileSizeString
    }

    //MARK: - UserDefaults Helpers

    func save(_ value: Any, forKey key:String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }

    func appVersionString() -> String {
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(versionString)(\(buildString))"
    }

    //MARK: - UI Related Helpers
    func mainThemeColor() -> UIColor {
        return UIColor(red:0.94, green:0.44, blue:0.19, alpha:1)
    }
    
    func showCellularHUD() -> Bool {
        guard let reachability = self.reachability else { return false }
        if !self.userCellularNetwork && !reachability.isReachableViaWiFi {
            DispatchQueue.main.async(execute: { () -> Void in
                self.showHudWithMessage(NSLocalizedString("Cellular data is turned off.", comment: "Cellular data is turned off."))
            })
            return true
        }
        return false
    }

    func showHudWithMessage(_ message: String, hideAfterDelay delay: Double = 1.0) {
        let hud = PKHUD.sharedHUD
        hud.contentView = PKHUDTextView(text: message)
        hud.show()
        hud.hide(afterDelay: delay)
    }

    func showHUD() -> PKHUD {
        let hud = PKHUD.sharedHUD
        hud.contentView = PKHUDProgressView()
        hud.show()
        return hud
    }

    func dismissMe(_ sender: UIBarButtonItem) {
        AppDelegate.shared().window?.rootViewController?.dismiss(animated: true, completion: nil)
    }

    func showTorrentSearchAlertInViewController(_ viewController:UIViewController?) {
        guard let viewController = viewController else { return } // Just do nothing...
        if (self.showCellularHUD()) { return }
        let alertController = UIAlertController(title: NSLocalizedString("Search", comment: "Search"), message: NSLocalizedString("Please enter video serial:", comment: "Please enter video serial:"), preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.keyboardType = .asciiCapable
        }
        let searchAction = UIAlertAction(title: NSLocalizedString("Search", comment: "Search"), style: .default) { _ in
            let keyword = alertController.textFields![0].text!
            let hud = self.showHUD()
            let dbSearchPath = self.dbSearchPath(withKeyword: keyword)
            let request = Alamofire.request(dbSearchPath)
            request.responseJSON(completionHandler: { [unowned self] response in
                if response.result.isSuccess {
                    guard let responseObject = response.result.value as? [String: AnyObject] else { return }
                    let success = responseObject["success"] as? Int == 1 ? true : false
                    if success {
                        let searchResultController = VPSearchResultController()
                        guard let torrents = responseObject["results"] as? [[String: AnyObject]] else { return }
                        searchResultController.torrents = torrents
                        searchResultController.keyword = keyword
                        if let navigationController = viewController as? UINavigationController {
                            navigationController.pushViewController(searchResultController, animated: true)
                        }
                        else {
                            let searchResultNavigationController = UINavigationController(rootViewController: searchResultController)
                            searchResultNavigationController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target:self, action: #selector(Helper.dismissMe(_:)))
                            viewController.present(searchResultNavigationController, animated: true, completion: nil)
                        }
                    }
                    else {
                        let errorMessage = responseObject["message"] as! String
                        self.showHudWithMessage(NSLocalizedString("\(errorMessage)", comment: "\(errorMessage)"))
                    }
                    hud.hide()
                }
                else {
                    hud.hide()
                    self.showHudWithMessage(NSLocalizedString("Connection failed.", comment: "Connection failed."))
                }
            })
        }
        alertController.addAction(searchAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        viewController.present(alertController, animated: true, completion: nil)
    }

    //MARK: - Transmission Remote Download Helpers
    func downloadTask(_ magnet:String, toDir dir: String, completionHandler:(() -> Void)? = nil,  errorHandler:(() -> Void)? = nil) {
        let params = ["method" : "torrent-add", "arguments": ["paused" : false, "download-dir" : dir, "filename" : magnet]] as [String : Any]
        let HTTPHeaders = ["X-Transmission-Session-Id" : sessionHeader]
        //, parameters: params, encoding: .JSON, headers: HTTPHeaders
        let request = Alamofire.request(self.transmissionRPCAddress(), method: .post, parameters: params, encoding: JSONEncoding(options: []),headers: HTTPHeaders)
        request.authenticate(user: usernameAndPassword.0, password: usernameAndPassword.1).responseJSON { response in
            if response.result.isSuccess {
                let responseObject = response.result.value as! [String: AnyObject]
                let result = responseObject["result"] as! String
                if result == "success" {
                    completionHandler?()
                }
            }
            else {
                errorHandler?()
            }
        }
    }

    func parseSessionAndAddTask(_ magnet:String, completionHandler:(() -> Void)? = nil, errorHandler:(() -> Void)? = nil) {
        let params = ["method" : "session-get"]
        let HTTPHeaders = ["X-Transmission-Session-Id" : sessionHeader]
        let request = Alamofire.request(self.transmissionRPCAddress(), method: .post, parameters: params, encoding: JSONEncoding(options: []),headers: HTTPHeaders)
        request.authenticate(user: usernameAndPassword.0, password: usernameAndPassword.1).responseJSON { [unowned self] response in
            if response.result.isSuccess {
                let responseObject = response.result.value as! [String:AnyObject]
                let result = responseObject["result"] as! String
                if result == "success" {
                    self.downloadPath = (responseObject["arguments"] as! [String: AnyObject])["download-dir"] as! String
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
                    let request = Alamofire.request(self.transmissionRPCAddress(), method: .post, parameters: params, encoding: JSONEncoding(options: []),headers: HTTPHeaders)
                    request.authenticate(user: self.usernameAndPassword.0, password: self.usernameAndPassword.1).responseJSON { [unowned self] response in
                        if response.result.isSuccess {
                            let responseObject = response.result.value as! [String:AnyObject]
                            let result = responseObject["result"] as! String
                            if result == "success" {
                                self.downloadPath = (responseObject["arguments"] as! [String: AnyObject])["download-dir"] as! String
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
                            AppDelegate.shared().window?.rootViewController?.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
                else {
                    errorHandler?()
                }
            }
        }
    }
}


