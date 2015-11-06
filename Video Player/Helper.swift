//
//  Helper.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import AFNetworking
import PKHUD

@objc
public class Helper : NSObject {
    public static let defaultHelper = Helper()

    private var sessionHeader: String = ""
    private var downloadPath: String = ""

    //MARK: - Properties
    var useSSL:Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.objectForKey(RequestUseSSL) == nil {
            defaults.setBool(true, forKey: RequestUseSSL)
            defaults.synchronize()
            return true
        }
        else {
            return defaults.boolForKey(RequestUseSSL)
        }
    }

    var SSL_ADD_S:String {
        return self.useSSL ? "s" : ""
    }

    var usernameAndPassword:[String] {
        let defaults = NSUserDefaults.standardUserDefaults()
        let username = defaults.objectForKey(TransmissionUserNameKey) as? String
        let password = defaults.objectForKey(TransmissionPasswordKey) as? String
        if username != nil && password != nil {
            return [username!, password!]
        }
        else {
            return ["username", "password"]
        }
    }

    var xunleiUsernameAndPassword:[String] {
        let defaults = NSUserDefaults.standardUserDefaults()
        let username = defaults.objectForKey(XunleiUserNameKey) as? String
        let password = defaults.objectForKey(XunleiPasswordKey) as? String
        if username != nil && password != nil {
            return [username!, password!]
        }
        else {
            return ["username", "password"]
        }
    }

    var customUserAgent: String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        guard let ua = defaults.stringForKey(CustomRequestUserAgent) else { return nil }
        return ua
    }

    var userCellularNetwork: Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.objectForKey(RequestUseCellularNetwork) == nil {
            defaults.setBool(true, forKey: RequestUseCellularNetwork)
            defaults.synchronize()
            return true
        }
        else {
            return defaults.boolForKey(RequestUseCellularNetwork)
        }
    }

    //MARK: - Link Helpers
    func torrentsListPath() -> String {
        return "http\(self.SSL_ADD_S)://\(self.baseLink())/torrents";
    }

    func baseLink() -> String {
        let defaults = NSUserDefaults.standardUserDefaults()
        var host = defaults.stringForKey(ServerHostKey)
        if host == nil { host = "192.168.1.1" }
        var port = defaults.stringForKey(ServerPortKey)
        if port == nil { port = "80" }
        var subPath = defaults.stringForKey(ServerPathKey)
        if subPath == nil || subPath == "/" {
            subPath = ""
        }
        else {
            if subPath!.substringToIndex(subPath!.startIndex.advancedBy(1)) != "/" {
                subPath = "/\(subPath)"
            }
            let lastCharIndex = subPath!.endIndex.advancedBy(-1)
            if subPath?.substringFromIndex(lastCharIndex) == "/" {
                subPath = subPath!.substringToIndex(lastCharIndex)
            }
        }
        return "\(host!):\(port!)\(subPath!)"
    }

    func fileLink(withPath path:String!) -> String {
        let defaults = NSUserDefaults.standardUserDefaults()
        var host = defaults.stringForKey(ServerHostKey)
        if host == nil { host = "192.168.1.1" }
        var port = defaults.stringForKey(ServerPortKey)
        if port == nil { port = "80" }
        var p = path
        if p == "" {
            p = "/"
        }
        else if (p.substringToIndex(p.startIndex.advancedBy(1)) != "/") {
            p = "/\(p)"
        }
        return "http\(self.SSL_ADD_S)://\(host!):\(port!)\(p)"
    }

    func transmissionServerAddress(withUserNameAndPassword withUnP:Bool = true) -> String {
        let defaults = NSUserDefaults.standardUserDefaults()
        var address: String
        if let addr = defaults.stringForKey(TransmissionAddressKey) {
            address = addr
        }
        else {
            address = "127.0.0.1:9091"
        }
        let userpass = self.usernameAndPassword
        if userpass[0].characters.count > 0 && userpass[1].characters.count > 0 && withUnP {
            return "http://\(userpass[0]):\(userpass[1])@\(address)"
        }
        else {
            return "http://\(address)"
        }
    }

    @objc(transmissionServerAddress)
    func _transmissionServerAddress() -> String {
        return self.transmissionServerAddress(withUserNameAndPassword: true)
    }

    func transmissionRPCAddress() -> String {
        return self.transmissionServerAddress(withUserNameAndPassword: false).vc_stringByAppendingPathComponents(["transmission", "rpc"])
    }

    func dbSearchPath(withKeyword keyword: String) -> String {
        let kw = keyword.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())
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
        return NSSearchPathForDirectoriesInDomains(.DocumentationDirectory, .UserDomainMask, true).first!
    }
    
    func freeDiskSpace() -> Int {
        guard let dictionary = try? NSFileManager.defaultManager().attributesOfFileSystemForPath(self.documentsDirectory()) else { return 0 }
        let freeFileSystemSizeInBytes = dictionary[NSFileSystemFreeSize] as! Int
        return freeFileSystemSizeInBytes
    }

    func localFileSize() -> Int {
        var size = 0
        let documentsDirectory = self.documentsDirectory()
        guard let fileEnumerator = NSFileManager.defaultManager().enumeratorAtPath(documentsDirectory) else { return 0 }
        for fileName in fileEnumerator {
            let filePath = documentsDirectory.vc_stringByAppendingPathComponent(fileName as! String)
            guard let attrs = try? NSFileManager.defaultManager().attributesOfFileSystemForPath(filePath) else { continue }
            size += (attrs[NSFileSize] as! Int)
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

    func save(value: AnyObject, forKey key:String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(value, forKey: key)
        defaults.synchronize()
    }

    //MARK: - AFNetworking Helpers
    @objc(refreshedManager)
    func _refreshedManager() -> AFHTTPSessionManager {
        return self.refreshedManager(withAuthentication: true, withJSON: false)
    }

    @objc(refreshedManagerWithAuthentication:)
    func _refreshedManager(withAuthentication auth: Bool = true) -> AFHTTPSessionManager {
        return self.refreshedManager(withAuthentication: auth, withJSON: false)
    }

    func refreshedManager(withAuthentication auth: Bool = true, withJSON JSON: Bool = false) -> AFHTTPSessionManager {
        let manager = AFHTTPSessionManager()
        if JSON { manager.requestSerializer = AFJSONRequestSerializer() }
        if auth {
            let usernameAndPassword = self.usernameAndPassword
            manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(usernameAndPassword[0], password: usernameAndPassword[1])
        }
        manager.requestSerializer.timeoutInterval = REQUEST_TIME_OUT
        manager.requestSerializer.setValue(self.customUserAgent, forHTTPHeaderField: "User-Agent")
        if self.useSSL {
            manager.securityPolicy.allowInvalidCertificates = true
            manager.securityPolicy.validatesDomainName = false
        }
        manager.requestSerializer.allowsCellularAccess = self.userCellularNetwork ? true : false
        return manager
    }

    //MARK: - UI Related Helpers
    func mainThemeColor() -> UIColor {
        return UIColor(red:0.94, green:0.44, blue:0.19, alpha:1)
    }

    func showCellularHUD() -> Bool {
        if !self.userCellularNetwork && !AFNetworkReachabilityManager.sharedManager().reachableViaWiFi {
            self.showHudWithMessage(NSLocalizedString("Cellular data is turned off.", comment: "Cellular data is turned off."))
            return true
        }
        return false
    }

    func showHudWithMessage(message: String) {
        let hud = PKHUD.sharedHUD
        hud.contentView = PKHUDTextView(text: message)
        hud.show()
        hud.hide(afterDelay: 2)
    }

    func showHUD() -> PKHUD {
        let hud = PKHUD.sharedHUD
        hud.contentView = PKHUDProgressView()
        hud.show()
        return hud
    }

    func dismissMe(sender: UIBarButtonItem) {
        AppDelegate.shared().window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func showTorrentSearchAlertInViewController(viewController:UIViewController) {
        if (self.showCellularHUD()) { return }
        let alertController = UIAlertController(title: NSLocalizedString("Search", comment: "Search"), message: NSLocalizedString("Please enter video serial:", comment: "Please enter video serial:"), preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.keyboardType = .ASCIICapable
        }
        let searchAction = UIAlertAction(title: NSLocalizedString("Search", comment: "Search"), style: .Default) { _ in
            let keyword = alertController.textFields![0].text!
            let hud = self.showHUD()
            let manager = self.refreshedManager()
            let dbSearchPath = self.dbSearchPath(withKeyword: keyword)
            manager.GET(dbSearchPath, parameters: nil, success: { (_, responseObject) -> Void in
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
                        searchResultNavigationController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target:self, action: "dismissMe")
                        viewController.presentViewController(searchResultNavigationController, animated: true, completion: nil)
                    }
                }
                else {
                    let errorMessage = responseObject["message"] as? String
                    self.showHudWithMessage(NSLocalizedString("\(errorMessage)", comment: "\(errorMessage)"))
                }
                hud.hide()
                }, failure: { (_, _) -> Void in
                    hud.hide()
                    self.showHudWithMessage(NSLocalizedString("Connection failed.", comment: "Connection failed."))
            })
        }
        alertController.addAction(searchAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        viewController.presentViewController(alertController, animated: true, completion: nil)
    }

    //MARK: - Transmission Remote Download Helpers
    func downloadTask(magnet:String, toDir dir: String, completionHandler:(() -> Void)? = nil,  errorHandler:(() -> Void)? = nil) {
        let params = ["method" : "torrent-add", "arguments": ["paused" : false, "download-dir" : dir, "filename" : magnet]]
        let manager = self.refreshedManager(withAuthentication: true, withJSON: true)
        manager.requestSerializer.setValue(sessionHeader, forHTTPHeaderField: "X-Transmission-Session-Id")
        manager.POST(self.transmissionRPCAddress(), parameters: params, success: { (_, responseObject) in
            let result = responseObject["result"] as! String
            if result == "success" {
                completionHandler?()
            }
        }, failure:  { (_, _) in
            errorHandler?()
        })
    }

    func parseSessionAndAddTask(magnet:String, completionHandler:(() -> Void)? = nil, errorHandler:(() -> Void)? = nil) {
        let sessionParams = ["method" : "session-get"]
        let manager = self.refreshedManager(withAuthentication: true, withJSON: true)
        manager.requestSerializer.setValue(sessionHeader, forHTTPHeaderField: "X-Transmission-Session-Id")
        manager.POST(self.transmissionRPCAddress(), parameters: sessionParams, success: { [unowned self] (_, responseObject) in
                let result = responseObject["result"] as! String
                if result == "success" {
                    self.downloadPath = (responseObject["arguments"] as! [String: AnyObject])["download-dir"] as! String
                    self.downloadTask(magnet, toDir: self.downloadPath, completionHandler: completionHandler, errorHandler: errorHandler)
                }
                else {
                    errorHandler?()
                }
            }, failure: { [unowned self] (task, _) in
                let response = task.response as! NSHTTPURLResponse
                if response.statusCode == 409 {
                    self.sessionHeader = response.allHeaderFields["X-Transmission-Session-Id"] as! String
                    let manager = self.refreshedManager(withAuthentication: true, withJSON: true)
                    manager.requestSerializer.setValue(self.sessionHeader, forHTTPHeaderField: "X-Transmission-Session-Id")
                    manager.POST(self.transmissionRPCAddress(), parameters: sessionParams, success: { (_, responseObject) in
                        let result = responseObject["result"] as! String
                        if result == "success" {
                            self.downloadPath = (responseObject["arguments"] as! [String: AnyObject])["download-dir"] as! String
                            self.downloadTask(magnet, toDir: self.downloadPath, completionHandler: completionHandler, errorHandler: errorHandler)
                        }
                        else {
                            errorHandler?()
                        }
                    }, failure: { (_, _) -> Void in
                        let alertController = UIAlertController(title: NSLocalizedString("Error", comment:"Error"), message: NSLocalizedString("Unkown error.", comment: "Unknow error."), preferredStyle: .Alert)
                        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil)
                        alertController.addAction(cancelAction)
                        AppDelegate.shared().window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
                    })
                }
                else {
                    errorHandler?()
                }
            })
    }
}


