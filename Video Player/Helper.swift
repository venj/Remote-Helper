//
//  Helper.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import AFNetworking
import Alamofire
import PKHUD
import ReachabilitySwift

@objc
public class Helper : NSObject {
    public static let defaultHelper = Helper()

    private var sessionHeader: String = ""
    private var downloadPath: String = ""
    var reachability: Reachability? = {
        return try? Reachability.reachabilityForInternetConnection()
    }()

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

    var usernameAndPassword:(String, String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let username = defaults.objectForKey(TransmissionUserNameKey) as? String
        let password = defaults.objectForKey(TransmissionPasswordKey) as? String
        if username != nil && password != nil {
            return (username!, password!)
        }
        else {
            return ("username", "password")
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

    //MARK: - UI Related Helpers
    func mainThemeColor() -> UIColor {
        return UIColor(red:0.94, green:0.44, blue:0.19, alpha:1)
    }

    func showCellularHUD() -> Bool {
        guard let reachability = self.reachability else { return false }
        if !self.userCellularNetwork && !reachability.isReachableViaWiFi() {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.showHudWithMessage(NSLocalizedString("Cellular data is turned off.", comment: "Cellular data is turned off."))
            })
            return true
        }
        return false
    }

    func showHudWithMessage(message: String, hideAfterDelay delay: Double = 1.0) {
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
            let dbSearchPath = self.dbSearchPath(withKeyword: keyword)
            let request = Alamofire.request(.GET, dbSearchPath)
            request.responseJSON(completionHandler: { response in
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
                            searchResultNavigationController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target:self, action: "dismissMe")
                            viewController.presentViewController(searchResultNavigationController, animated: true, completion: nil)
                        }
                    }
                    else {
                        let errorMessage = responseObject["message"] as? String
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
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        viewController.presentViewController(alertController, animated: true, completion: nil)
    }

    //MARK: - Transmission Remote Download Helpers
    func downloadTask(magnet:String, toDir dir: String, completionHandler:(() -> Void)? = nil,  errorHandler:(() -> Void)? = nil) {
        let params = ["method" : "torrent-add", "arguments": ["paused" : false, "download-dir" : dir, "filename" : magnet]]
        let HTTPHeaders = ["X-Transmission-Session-Id" : sessionHeader]
        let request = Alamofire.request(.POST, self.transmissionRPCAddress(), parameters: params, encoding: .JSON, headers: HTTPHeaders)
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

    func parseSessionAndAddTask(magnet:String, completionHandler:(() -> Void)? = nil, errorHandler:(() -> Void)? = nil) {
        let params = ["method" : "session-get"]
        let HTTPHeaders = ["X-Transmission-Session-Id" : sessionHeader]
        let request = Alamofire.request(.POST, self.transmissionRPCAddress(), parameters: params, encoding: .JSON, headers: HTTPHeaders)
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
                if response.response!.statusCode == 409 {
                    self.sessionHeader = response.response!.allHeaderFields["X-Transmission-Session-Id"] as! String

                    let params = ["method" : "session-get"]
                    let HTTPHeaders = ["X-Transmission-Session-Id" : self.sessionHeader]
                    let request = Alamofire.request(.POST, self.transmissionRPCAddress(), parameters: params, encoding: .JSON, headers: HTTPHeaders)
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
                            let alertController = UIAlertController(title: NSLocalizedString("Error", comment:"Error"), message: NSLocalizedString("Unkown error.", comment: "Unknow error."), preferredStyle: .Alert)
                            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil)
                            alertController.addAction(cancelAction)
                            AppDelegate.shared().window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
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


