//
//  Configuration.swift
//  Remote Helper
//
//  Created by venj on 2017/12/12.
//  Copyright © 2017年 Home. All rights reserved.
//

import Foundation

open class Configuration {

    open static let shared = Configuration()
    private let defaults = UserDefaults.standard
    private let defaultValues: [String: Any] = [ViewedResources: [],
                                 RequestUseSSL: true,
                                 TransmissionUserNameKey: "username",
                                 TransmissionPasswordKey: "password",
                                 ServerHostKey: "192.168.1.1",
                                 ServerPortKey: "80",
                                 ServerPathKey: "/",
                                 TransmissionAddressKey: "127.0.0.1:9091",
                                 RequestUseCellularNetwork: true,
                                 MiAccountUsernameKey: "",
                                 MiAccountPasswordKey: "",
                                 IntelligentTorrentDownload: false,
                                 PrefersMagnet: true,
                                 ]
    private init() {
        defaults.register(defaults: defaultValues)
        defaults.synchronize()
    }

    open var hasTorrentServer: Bool {
        get {
            // Treat any string less than 5 chars as invalid address.
            if serverHost.count >= 5 {
                return true
            }
            return false
        }
    }

    open var viewedResources: [String] {
        get {
            return defaults.array(forKey: ViewedResources) as? [String] ?? []
        }
        set {
            defaults.set(newValue, forKey: ViewedResources)
            defaults.synchronize()
        }
    }

    open var serverHost: String {
        get {
            return defaults.string(forKey: ServerHostKey) ?? defaultValues[ServerHostKey] as! String
        }
        set {
            defaults.set(newValue, forKey: ServerHostKey)
            defaults.synchronize()
        }
    }

    open var serverPort: String {
        get {
            return defaults.string(forKey: ServerPortKey) ?? defaultValues[ServerPortKey] as! String
        }
        set {
            defaults.set(newValue, forKey: ServerPortKey)
            defaults.synchronize()
        }
    }

    open var serverPath: String {
        get {
            return defaults.string(forKey: ServerPathKey) ?? "/"
        }
        set {
            defaults.set(newValue, forKey: ServerPathKey)
            defaults.synchronize()
        }
    }

    open var requestUsesSSL: Bool {
        get {
            return defaults.bool(forKey: RequestUseSSL)
        }
        set {
            defaults.set(newValue, forKey: RequestUseSSL)
            defaults.synchronize()
        }
    }

    open var scheme: String {
        return requestUsesSSL ? "https" : "http"
    }

    open var transmissionUsername: String {
        get {
            return defaults.string(forKey: TransmissionUserNameKey) ?? defaultValues[TransmissionUserNameKey] as! String
        }
        set {
            defaults.set(newValue, forKey: TransmissionUserNameKey)
            defaults.synchronize()
        }
    }

    open var transmissionPassword: String {
        get {
            return defaults.string(forKey: TransmissionPasswordKey) ?? defaultValues[TransmissionPasswordKey] as! String
        }
        set {
            defaults.set(newValue, forKey: TransmissionPasswordKey)
            defaults.synchronize()
        }
    }

    open var transmissionAddress: String {
        get {
            return defaults.string(forKey: TransmissionAddressKey) ?? defaultValues[TransmissionAddressKey] as! String
        }
        set {
            defaults.set(newValue, forKey: TransmissionAddressKey)
            defaults.synchronize()
        }
    }

    open var userCellularNetwork: Bool {
        get {
            return defaults.bool(forKey: RequestUseCellularNetwork)
        }
        set {
            defaults.set(newValue, forKey: RequestUseCellularNetwork)
            defaults.synchronize()
        }
    }

    open var isIntelligentTorrentDownloadEnabled: Bool {
        get {
            return defaults.bool(forKey: IntelligentTorrentDownload)
        }
        set {
            defaults.set(newValue, forKey: IntelligentTorrentDownload)
            defaults.synchronize()
        }
    }

    open var prefersManget: Bool {
        get {
            return defaults.bool(forKey: PrefersMagnet)
        }
        set {
            defaults.set(newValue, forKey: PrefersMagnet)
            defaults.synchronize()
        }
    }

    open var customUserAgent: String? {
        get {
            return defaults.string(forKey: CustomRequestUserAgent)
        }
        set {
            defaults.set(newValue, forKey: CustomRequestUserAgent)
            defaults.synchronize()
        }
    }

    open var miAccountUsername: String {
        get {
            return defaults.string(forKey: MiAccountUsernameKey) ?? defaultValues[MiAccountUsernameKey] as! String
        }
        set {
            defaults.set(newValue, forKey: MiAccountUsernameKey)
            defaults.synchronize()
        }
    }

    open var miAccountPassword: String {
        get {
            return defaults.string(forKey: MiAccountPasswordKey) ?? defaultValues[MiAccountPasswordKey] as! String
        }
        set {
            defaults.set(newValue, forKey: MiAccountPasswordKey)
            defaults.synchronize()
        }
    }

    func save(_ value: Any, forKey key:String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }
    
    //MARK: - Link Helpers
    var baseLink: String {
        let host = serverHost
        let port = serverPort
        var subPath = (serverPath == "/") ? "" : serverPath

        if subPath.count > 0 && subPath != "/" {
            if subPath.last == "/" {
                subPath.removeLast()
            }
            if !subPath.isEmpty, subPath.first != "/" {
                subPath = "/\(subPath)"
            }
        }

        return "\(scheme)://\(host):\(port)\(subPath)"
    }

    var torrentsListPath: String {
        return baseLink + "/torrents?stats=true"
    }

    func torrentPath(withInfoHash infoHash: String) -> String {
        return baseLink + "/torrent/\(infoHash)"
    }

    func dbSearchPath(withKeyword keyword: String) -> String {
        let kw = keyword.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
        let escapedKeyword = kw == nil ? "" : kw!
        return baseLink + "/db_search?keyword=\(escapedKeyword)"
    }

    func searchPath(withKeyword keyword: String) -> String {
        return baseLink + "/search/\(keyword)"
    }

    func hashTorrent(withName name: String) -> String{
        return baseLink + "/hash/\(name)"
    }

    func transmissionServerAddress(withUserNameAndPassword withUnP: Bool = true) -> String {
        if transmissionUsername.count > 0 && transmissionPassword.count > 0 && withUnP {
            return "http://\(transmissionUsername):\(transmissionPassword)@\(transmissionAddress)"
        }
        else {
            return "http://\(transmissionAddress)"
        }
    }

    func transmissionRPCAddress() -> String {
        return transmissionServerAddress(withUserNameAndPassword: false).vc_stringByAppendingPathComponents(["transmission", "rpc"])
    }
}
