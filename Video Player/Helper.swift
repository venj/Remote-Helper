//
//  Helper.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit

@objc
public class Helper : NSObject {
    public static let defaultHelper = Helper()
    public static let sharedAPI = HYXunleiLixianAPI()

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

    func transmissionServerAddress() -> String {
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

    @objc(refreshedManager)
    func _refreshedManager() -> AFHTTPSessionManager {
        return self.refreshedManager(withAuthentication: true, withJSON: false)
    }

    @objc(refreshedManagerWithAuthentication:)
    func _refreshedManager(withAuthentication auth: Bool = true) -> AFHTTPSessionManager {
        return self.refreshedManager(withAuthentication: auth, withJSON: false)
    }

    func fileSizeString(withInteger integer: Int) -> String {
        return integer.fileSizeString
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

//    - (void)showTorrentSearchAlertInNavigationController:(UINavigationController *)navigationController;
//    - (void)showHudWithMessage:(NSString *)message inView:(UIView *)aView;
//    - (NSURL *)videoPlayURLWithPath:(NSString *)path;
//    - (void)parseSessionAndAddTask:(NSString *)magnet completionHandler:(void (^__strong)(void))completionHandler errorHandler:(void (^__strong)(void))errorHandler;
//    - (NSString *)customUserAgent;
//    - (BOOL)useSSL;
//    - (BOOL)useCellularNetwork;
//    - (BOOL)showCellularHUD;


    
}


