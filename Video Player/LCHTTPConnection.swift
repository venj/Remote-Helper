//
//  LCHTTPConnection.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@objc
public class LCHTTPConnection : NSObject {
    public var responseCookies : [NSHTTPCookie] = []
    private var postData : [[String: String]] = []

    // Singleton
    public static let sharedZZHTTPConnection = LCHTTPConnection()

    public func get(urlString:String) -> String? {
        let urlRequest = NSMutableURLRequest()
        urlRequest.URL = NSURL(string: urlString)
        urlRequest.addValue("User-Agent:Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.106 Safari/535.2" , forHTTPHeaderField: "User-Agent")
        urlRequest.timeoutInterval = 15
        urlRequest.addValue("http://lixian.vip.xunlei.com/", forHTTPHeaderField: "Referer")
        urlRequest.addValue("text/xml", forHTTPHeaderField: "Content-Type")
        urlRequest.HTTPMethod = "GET"
        urlRequest.cachePolicy = .ReloadIgnoringLocalCacheData

        refreshCookie(forRequest: urlRequest)
        return send(syncRequest: urlRequest)
    }

    public func post(urlString:String, withBody body: String) -> String? {
        let urlRequest = NSMutableURLRequest()
        urlRequest.URL = NSURL(string: urlString)
        urlRequest.HTTPMethod = "POST"
        urlRequest.addValue("text/xml", forHTTPHeaderField: "Content-Type") // is this necessary?
        let boundary = NSProcessInfo.processInfo().globallyUniqueString
        let boundaryString = "multipart/form-data; boundary=\(boundary)"
        urlRequest.addValue(boundaryString, forHTTPHeaderField: "Content-Type")
        urlRequest.cachePolicy = .ReloadIgnoringLocalCacheData

        let boundarySeparator = "--\(boundary)\r\n"
        let postBody = NSMutableData()
        postBody.appendData(boundarySeparator.dataUsingEncoding(NSUTF8StringEncoding)!)
        let endItemBoundary = "\r\n--\(boundary)\r\n"

        var i = 0
        for kv in postData {
            let value = kv["key"]!
            let str = String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", arguments: [value])
            postBody.appendData(str.dataUsingEncoding(NSUTF8StringEncoding)!)
            ++i
            if i != postData.count {
                postBody.appendData(endItemBoundary .dataUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        urlRequest.HTTPBody = postBody

        refreshCookie(forRequest: urlRequest)
        return send(syncRequest: urlRequest)
    }

    public func postBTFile(path:String) -> String? {
        guard let torrentData = NSData(contentsOfFile: path) else { return nil }
        let fileName = path.componentsSeparatedByString("/").last!
        let urlRequest = NSMutableURLRequest()
        urlRequest.URL = NSURL(string: "http://dynamic.cloud.vip.xunlei.com/interface/torrent_upload")
        urlRequest.addValue("User-Agent:Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.106 Safari/535.2" , forHTTPHeaderField: "User-Agent")
        urlRequest.addValue("http://lixian.vip.xunlei.com/", forHTTPHeaderField: "Referer")
        urlRequest.HTTPMethod = "POST"
        let boundary = NSProcessInfo.processInfo().globallyUniqueString
        let boundaryString = "multipart/form-data; boundary=\(boundary)"
        urlRequest.addValue(boundaryString, forHTTPHeaderField: "Content-Type")
        urlRequest.cachePolicy = .ReloadIgnoringLocalCacheData
        // boundary sepetator
        let boundarySeparator = "--\(boundary)\r\n"
        // add post body
        let postBody = NSMutableData()
        // add post data
        postBody.appendData(boundarySeparator.dataUsingEncoding(NSUTF8StringEncoding)!)
        let endItemBoundary = "\r\n--\(boundary)\r\n"
        let finalItemBoundary = "\r\n--\(boundary)--\r\n"

        // header
        postBody.appendData(boundarySeparator.dataUsingEncoding(NSUTF8StringEncoding)!)
        let header = String(format:"Content-Disposition: form-data; name=\"filepath\";\r\nfilename=\"%@\"\r\nContent-Type: application/x-bittorrent\r\n\r\n", arguments: [fileName])
        postBody.appendData(header.dataUsingEncoding(NSUTF8StringEncoding)!)

        // torrent data
        postBody.appendData(torrentData)
        postBody.appendData(endItemBoundary.dataUsingEncoding(NSUTF8StringEncoding)!)
        // timestamp
        postBody.appendData("Content-Disposition: form-data; name=\"random\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        postBody.appendData(currentTimeString().dataUsingEncoding(NSUTF8StringEncoding)!)
        postBody.appendData(endItemBoundary.dataUsingEncoding(NSUTF8StringEncoding)!)

        // tasksign
        postBody.appendData("Content-Disposition: form-data; name=\"interfrom\"\r\n\r\ntask".dataUsingEncoding(NSUTF8StringEncoding)!)
        postBody.appendData(finalItemBoundary.dataUsingEncoding(NSUTF8StringEncoding)!)

        urlRequest.HTTPBody = postBody
        refreshCookie(forRequest: urlRequest)
        return send(syncRequest: urlRequest)
    }

    public func post(urlString:String) -> String? {
        let urlRequest = NSMutableURLRequest()
        urlRequest.URL = NSURL(string: urlString)
        urlRequest.HTTPMethod = "POST"
        urlRequest.addValue("application/x-www-form-urlencoded;charset=utf-8", forHTTPHeaderField:"Content-Type")
        urlRequest.cachePolicy = .ReloadIgnoringLocalCacheData

        var postValueString = ""
        for kv in self.postData {
            let key = kv["key"]
            let value = kv["value"]
            postValueString += "\(key!)=\(value!)&"
        }
        urlRequest.HTTPBody = postValueString.dataUsingEncoding(NSUTF8StringEncoding)

        refreshCookie(forRequest: urlRequest)
        return send(syncRequest: urlRequest)
    }

    public func setCookie(withKey key:String, value:String) -> NSHTTPCookie {
        var properties:[String: AnyObject] = [:]
        properties[NSHTTPCookieValue] = value
        properties[NSHTTPCookieName] = key
        properties[NSHTTPCookieDomain] = ".vip.xunlei.com"
        properties[NSHTTPCookiePath] = "/"
        properties[NSHTTPCookieExpires] = NSDate(timeIntervalSinceNow: 2629743)
        let cookie = NSHTTPCookie(properties: properties)
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        cookieStorage.cookieAcceptPolicy = .Always
        cookieStorage.setCookie(cookie!)
        responseCookies.append(cookie!)
        return cookie!
    }

    @objc(setPostValue:forKey:)
    public func set(PostValue value:String, forKey key:String?) {
        if key == nil { return }
        var i = 0
        for val in postData {
            if val["key"] == key {
                postData.removeAtIndex(i)
            }
            ++i
        }
        var kv: [String:String] = [:]
        kv["key"] = key
        kv["value"] = value
        self.postData.append(kv)
    }

    private func currentTimeString() -> String {
        let UTCTime = NSDate().timeIntervalSince1970
        let currentTime = String(format:"%f", arguments: [UTCTime * 1000])
        return currentTime.componentsSeparatedByString(".")[0]
    }

    private func refreshCookie(forRequest request:NSMutableURLRequest) {
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        var cookieString = ""
        for cookie in cookieStorage.cookies! {
            if cookie.domain.hasSuffix(".xunlei.com") {
                //cookieString += "\(cookie.name)=\(cookie.value); "
                cookieString = cookieString.stringByAppendingString("\(cookie.name)=\(cookie.value); ")
            }
        }
        request.setValue(cookieString, forHTTPHeaderField: "Cookie")
    }

    private func send(syncRequest request: NSMutableURLRequest) -> String? {
        var urlResponse: NSURLResponse? = nil // should be exactly like this!!!
        do {
            let responseData = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &urlResponse)
            let responseString = String(data: responseData, encoding: NSUTF8StringEncoding)
            guard let response = urlResponse as? NSHTTPURLResponse else { return nil }
            if (response.allHeaderFields["Set-Cookie"] != nil) {
                let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(response.allHeaderFields as! [String:String], forURL: NSURL(string: ".vip.xunlei.com")!)
                for cookie in cookies {
                    setCookie(withKey: cookie.name, value: cookie.value)
                }
            }
            let statusCode = response.statusCode
            if statusCode >= 200 && statusCode < 400 {
                return responseString
            }
            else { // Error
                print("Error status: \(statusCode), \(NSHTTPURLResponse.localizedStringForStatusCode(statusCode))")
            }
        }
        catch let error as NSError {
            print("Network error: \(error.localizedDescription)")
        }
        return nil
    }
}