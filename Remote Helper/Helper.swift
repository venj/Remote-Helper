//
//  Helper.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/2.
//  Copyright © 2015 Home. All rights reserved.
//

import Foundation
import Alamofire

@objc
open class Helper : NSObject {
    open static let shared = Helper()

    var sessionHeader: String = ""
    var downloadPath: String = ""

    // AD black list.
    var kittenBlackList: [String] = ["正品香烟", "中铧", "稥湮", "威信", "试抽"]

    func kittenSearchPath(withKeyword keyword: String, page: Int = 1) -> String {
        let kw = keyword.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let escapedKeyword = kw == nil ? "" : kw!
        let source = Configuration.shared.torrentKittenSource
        switch source {
        case .bt177:
            return "http://www.bt177.me/word/\(escapedKeyword)_\(page).html"
        default: // 0 or other out of bound value
            return "\(Configuration.shared.baseLink)/kitty/\(escapedKeyword)/\(page)"
        }
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

    func appVersionString() -> String {
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(versionString)(\(buildString))"
    }


    func infoHash(fromMagnet magnet: String) -> String {
        return magnet.components(separatedBy: "&")[0].components(separatedBy: ":").last!
    }

    func downloadTorrent(withMagnet magnet: String, completion: @escaping (String) -> Void) {
        if Configuration.shared.prefersManget {
            completion(magnet)
            return
        }
        let hash = infoHash(fromMagnet: magnet)
        let address = Configuration.shared.torrentPath(withInfoHash: hash)
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("\(hash).torrent")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        Alamofire.download(address, to: destination).responseData { (response) in
            if response.error == nil, response.result.isSuccess, let data = response.result.value {
                if data.count < 512 { // Possibly not a torrent file.
                    completion(magnet)
                }
                else {
                    completion(data.base64EncodedString())
                }
            }
            else {
                completion(magnet)
            }
        }
    }

    //MARK: - Transmission Remote Download Helpers
    func downloadTask(_ magnet: String, toDir dir: String, completionHandler:(() -> Void)? = nil,  errorHandler:(() -> Void)? = nil) {
        func addTorrentInfo(_ magnetOrMetaInfo: String) {
            var params = ["method" : "torrent-add"] as [String : Any]
            if magnetOrMetaInfo.prefix(6) == "magnet" {
                params["arguments"] = ["paused" : false, "download-dir" : dir, "filename": magnetOrMetaInfo]
            }
            else {
                params["arguments"] = ["paused" : false, "download-dir" : dir, "metainfo": magnetOrMetaInfo]
            }
            let HTTPHeaders = ["X-Transmission-Session-Id" : self.sessionHeader]
            let request = Alamofire.request(Configuration.shared.transmissionRPCAddress(), method: .post, parameters: params, encoding: JSONEncoding(options: []),headers: HTTPHeaders)
            request.authenticate(user: Configuration.shared.transmissionUsername, password: Configuration.shared.transmissionPassword).responseJSON { response in
                if response.result.isSuccess {
                    let responseObject = response.result.value as! [String: Any]
                    let result = responseObject["result"] as! String
                    if result == "success" {
                        completionHandler?()
                    }
                    else {
                        errorHandler?()
                    }
                }
                else {
                    errorHandler?()
                }
            }
        }

        if magnet.prefix(6) != "magnet" {
            addTorrentInfo(magnet)
        }
        else {
            downloadTorrent(withMagnet: magnet) { (file) in
                addTorrentInfo(file)
            }
        }
    }
}


