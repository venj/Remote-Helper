//
//  Configuration.swift
//  Remote Helper
//
//  Created by venj on 2017/12/12.
//  Copyright © 2017年 Home. All rights reserved.
//

import Foundation
import Alamofire

open class Configuration {

    public static let shared = Configuration()
    private let defaults = UserDefaults.standard
    private let defaultValues: [String: Any] = [ViewedResources: [String](),
                                 RequestUseSSL: true,
                                 TransmissionUserNameKey: "username",
                                 TransmissionPasswordKey: "password",
                                 ServerHostKey: "192.168.1.1",
                                 ServerPortKey: "80",
                                 ServerPathKey: "/",
                                 TransmissionAddressKey: "127.0.0.1:9091",
                                 XunleiAddressKey: "",
                                 XunleiPortKey: "",
                                 XunleiUseSSLKey: false,
                                 XunleiDownloadDirectoryKey: "",
                                 RequestUseCellularNetwork: true,
                                 AutoPlayGIFInGridKey: false,
                                 AutoPlayGIFInPreviewKey: true,
                                 MiAccountUsernameKey: "",
                                 MiAccountPasswordKey: "",
                                 IntelligentTorrentDownload: false,
                                 PrefersMagnet: true,
                                 TorrentKittenSource: KittenSource.main.rawValue,
                                 DyttBaseAddress: "https://www.dytt8899.com",
                                 ]
    private init() {
        defaults.register(defaults: defaultValues)
        migrateLegacyXunleiAddress()
        defaults.synchronize()
    }

    private func splitXunleiAddress(_ address: String) -> (host: String, port: String)? {
        let value = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains("://"),
              let separator = value.lastIndex(of: ":") else {
            return nil
        }

        let host = String(value[..<separator])
        let port = String(value[value.index(after: separator)...])
        guard !host.isEmpty, !port.isEmpty, Int(port) != nil else {
            return nil
        }
        return (host, port)
    }

    private func migrateLegacyXunleiAddress() {
        let address = defaults.string(forKey: XunleiAddressKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let parts = splitXunleiAddress(address) else {
            return
        }

        defaults.set(parts.host, forKey: XunleiAddressKey)
        defaults.set(parts.port, forKey: XunleiPortKey)
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

    open var xunleiAddress: String {
        get {
            return defaults.string(forKey: XunleiAddressKey) ?? defaultValues[XunleiAddressKey] as! String
        }
        set {
            defaults.set(newValue, forKey: XunleiAddressKey)
            defaults.synchronize()
        }
    }

    open var xunleiPort: String {
        get {
            return defaults.string(forKey: XunleiPortKey) ?? defaultValues[XunleiPortKey] as! String
        }
        set {
            defaults.set(newValue, forKey: XunleiPortKey)
            defaults.synchronize()
        }
    }

    open var xunleiUsesSSL: Bool {
        get {
            return defaults.bool(forKey: XunleiUseSSLKey)
        }
        set {
            defaults.set(newValue, forKey: XunleiUseSSLKey)
            defaults.synchronize()
        }
    }

    open var xunleiDownloadDirectory: String {
        get {
            return defaults.string(forKey: XunleiDownloadDirectoryKey) ?? defaultValues[XunleiDownloadDirectoryKey] as! String
        }
        set {
            defaults.set(newValue, forKey: XunleiDownloadDirectoryKey)
            defaults.synchronize()
        }
    }

    open var hasXunleiServer: Bool {
        return !xunleiAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    open var dyttBaseAddress: String {
        get {
            return defaults.string(forKey: DyttBaseAddress) ?? defaultValues[DyttBaseAddress] as! String
        }
        set {
            defaults.set(newValue, forKey: DyttBaseAddress)
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

    open var torrentKittenSource: KittenSource {
        get {
            return KittenSource(rawValue: defaults.integer(forKey: TorrentKittenSource)) ?? .main
        }
        set {
            defaults.set(newValue.rawValue, forKey: TorrentKittenSource)
            defaults.synchronize()
        }
    }
    
    // Use the Same key as old torrent kitten, because this will replace torrent kitten.
    open var catTorrentSource: CatSource {
        get {
            return CatSource(rawValue: defaults.integer(forKey: TorrentKittenSource)) ?? .main
        }
        set {
            defaults.set(newValue.rawValue, forKey: TorrentKittenSource)
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

    open var autoPlayGIFInGrid: Bool {
        get {
            return defaults.bool(forKey: AutoPlayGIFInGridKey)
        }
        set {
            defaults.set(newValue, forKey: AutoPlayGIFInGridKey)
            defaults.synchronize()
        }
    }

    open var autoPlayGIFInPreview: Bool {
        get {
            return defaults.bool(forKey: AutoPlayGIFInPreviewKey)
        }
        set {
            defaults.set(newValue, forKey: AutoPlayGIFInPreviewKey)
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
        return baseLink + "/torrents"
    }
    
    var headers: HTTPHeaders {
        return [
            "User-Agent": customUserAgent ?? "iOS Example/1.0 (com.alamofire.iOS-Example; build:1; iOS 13.0.0) Alamofire/5.0.0",
            "Accept": "application/json"
        ]
    }

    func torrentPath(withInfoHash infoHash: String) -> String {
        return baseLink + "/torrent/\(infoHash)"
    }

    func searchPath(withKeyword keyword: String) -> String {
        return baseLink + "/search/\(keyword)"
    }
    
    func catSearchPath(withKeyword keyword: String, source: CatSource, page: Int = 1) -> String {
        return baseLink + "/nyaa?search=\(keyword.percentEncodedString)&sukebei=\(source.rawValue)&page=\(page)"
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

    func xunleiServerAddress(withUserNameAndPassword _: Bool = false) -> String {
        var address = xunleiAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if !address.contains("://") {
            let hasPort = splitXunleiAddress(address) != nil
            if !hasPort {
                let port = xunleiPort.trimmingCharacters(in: .whitespacesAndNewlines)
                if !port.isEmpty {
                    address += ":\(port)"
                }
            }
            address = "\(xunleiUsesSSL ? "https" : "http")://\(address)"
        }

        return address
    }

    func xunleiPanelAddress(withUserNameAndPassword withUnP: Bool = false) -> String {
        return xunleiServerAddress(withUserNameAndPassword: withUnP).vc_stringByAppendingPathComponents([
            "webman", "3rdparty", "pan-xunlei-com", "index.cgi"
        ])
    }
}
