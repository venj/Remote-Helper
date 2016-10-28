//
//  LCHTTPConnection.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@objc
open class LCHTTPConnection : NSObject {
    fileprivate var postData : [[String: String]] = []

    // Singleton
    open static let sharedConnection = LCHTTPConnection()

    open func get(_ urlString:String) -> String? {
        let urlRequest = NSMutableURLRequest()
        urlRequest.url = URL(string: urlString)
        urlRequest.addValue(DEFAULT_USER_AGENT , forHTTPHeaderField: "User-Agent")
        urlRequest.timeoutInterval = 15
        urlRequest.addValue(DEFAULT_REFERER, forHTTPHeaderField: "Referer")
        urlRequest.addValue("text/xml", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "GET"
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData

        LXAPIHelper.refreshCookie(forRequest: urlRequest)
        return LXAPIHelper.send(syncRequest: urlRequest)
    }

    open func post(_ urlString:String, withBody body: String) -> String? {
        let urlRequest = NSMutableURLRequest()
        urlRequest.url = URL(string: urlString)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("text/xml", forHTTPHeaderField: "Content-Type") // is this necessary?
        let boundary = ProcessInfo.processInfo.globallyUniqueString
        let boundaryString = "multipart/form-data; boundary=\(boundary)"
        urlRequest.addValue(boundaryString, forHTTPHeaderField: "Content-Type")
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData

        let boundarySeparator = "--\(boundary)\r\n"
        let postBody = NSMutableData()
        postBody.append(boundarySeparator.data(using: String.Encoding.utf8)!)
        let endItemBoundary = "\r\n--\(boundary)\r\n"

        var i = 0
        for kv in postData {
            let value = kv["key"]!
            let str = String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", arguments: [value])
            postBody.append(str.data(using: String.Encoding.utf8)!)
            i += 1
            if i != postData.count {
                postBody.append(endItemBoundary .data(using: String.Encoding.utf8)!)
            }
        }
        urlRequest.httpBody = postBody as Data

        LXAPIHelper.refreshCookie(forRequest: urlRequest)
        return LXAPIHelper.send(syncRequest: urlRequest)
    }

    open func postBTFile(_ path:String) -> String? {
        guard let torrentData = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        let fileName = path.components(separatedBy: "/").last!
        let urlRequest = NSMutableURLRequest()
        urlRequest.url = URL(string: "http://dynamic.cloud.vip.xunlei.com/interface/torrent_upload")
        urlRequest.addValue(DEFAULT_USER_AGENT , forHTTPHeaderField: "User-Agent")
        urlRequest.addValue(DEFAULT_REFERER, forHTTPHeaderField: "Referer")
        urlRequest.httpMethod = "POST"
        let boundary = ProcessInfo.processInfo.globallyUniqueString
        let boundaryString = "multipart/form-data; boundary=\(boundary)"
        urlRequest.addValue(boundaryString, forHTTPHeaderField: "Content-Type")
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        // boundary sepetator
        let boundarySeparator = "--\(boundary)\r\n"
        // add post body
        let postBody = NSMutableData()
        // add post data
        postBody.append(boundarySeparator.data(using: String.Encoding.utf8)!)
        let endItemBoundary = "\r\n--\(boundary)\r\n"
        let finalItemBoundary = "\r\n--\(boundary)--\r\n"

        // header
        postBody.append(boundarySeparator.data(using: String.Encoding.utf8)!)
        let header = String(format:"Content-Disposition: form-data; name=\"filepath\";\r\nfilename=\"%@\"\r\nContent-Type: application/x-bittorrent\r\n\r\n", arguments: [fileName])
        postBody.append(header.data(using: String.Encoding.utf8)!)

        // torrent data
        postBody.append(torrentData)
        postBody.append(endItemBoundary.data(using: String.Encoding.utf8)!)
        // timestamp
        postBody.append("Content-Disposition: form-data; name=\"random\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        postBody.append(LXAPIHelper.currentTimeString().data(using: String.Encoding.utf8)!)
        postBody.append(endItemBoundary.data(using: String.Encoding.utf8)!)

        // tasksign
        postBody.append("Content-Disposition: form-data; name=\"interfrom\"\r\n\r\ntask".data(using: String.Encoding.utf8)!)
        postBody.append(finalItemBoundary.data(using: String.Encoding.utf8)!)

        urlRequest.httpBody = postBody as Data
        LXAPIHelper.refreshCookie(forRequest: urlRequest)
        return LXAPIHelper.send(syncRequest: urlRequest)
    }

    open func post(_ urlString:String) -> String? {
        let urlRequest = NSMutableURLRequest()
        urlRequest.url = URL(string: urlString)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/x-www-form-urlencoded;charset=utf-8", forHTTPHeaderField:"Content-Type")
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData

        var postValueString = ""
        for kv in self.postData {
            let key = kv["key"]
            let value = kv["value"]
            postValueString += "\(key!)=\(value!)&"
        }
        urlRequest.httpBody = postValueString.data(using: String.Encoding.utf8)

        LXAPIHelper.refreshCookie(forRequest: urlRequest)
        return LXAPIHelper.send(syncRequest: urlRequest)
    }

    @objc(setPostValue:forKey:)
    open func set(PostValue value:String, forKey key:String?) {
        if key == nil { return }
        var i = 0
        for val in postData {
            if val["key"] == key {
                postData.remove(at: i)
            }
            i += 1
        }
        var kv: [String:String] = [:]
        kv["key"] = key
        kv["value"] = value
        self.postData.append(kv)
    }
}
