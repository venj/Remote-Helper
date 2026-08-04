//
//  Constants.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/4.
//  Copyright © 2015 Home. All rights reserved.
//

import Foundation

let REQUEST_TIME_OUT = 60.0
let ServerHostKey = "kServerHostKey"
let ServerPortKey = "kServerPortKey"
let ServerPathKey = "kServerPathKey"
let TransmissionAddressKey = "kTransmissionAddressKey"
let TransmissionUserNameKey = "kTransmissionUserNameKey"
let TransmissionPasswordKey = "kTransmissionPasswordKey"
let XunleiAddressKey = "kXunleiAddressKey"
let XunleiPortKey = "kXunleiPortKey"
let XunleiUseSSLKey = "kXunleiUseSSLKey"
let XunleiDownloadDirectoryKey = "kXunleiDownloadDirectoryKey"
let MiAccountUsernameKey = "kMiAccountUsernameKey"
let MiAccountPasswordKey = "kMiAccountPasswordKey"
let ServerSetupDone = "kServerSetupDone"
let CurrentVersionKey = "kCurrentVersionKey"
let ClearCacheOnExitKey = "kClearCacheOnExitKey"
let ClearCacheNowKey = "kClearCacheNowKey"
let ImageCacheSizeKey = "kImageCacheSizeKey"
let AsyncAddCloudTaskKey = "kAsyncAddCloudTaskKey"
let PasscodeLockStatus = "kPasscodeLockStatus"
let PasscodeLockConfig = "kPasscodeLockConfig"
let LocalFileSize = "kLocalFileSize"
let DeviceFreeSpace = "kDeviceFreeSpace"
let RequestUseSSL = "kRequestUseSSL"
let RequestUseCellularNetwork = "kRequestUseCellularNetwork"
let CustomRequestUserAgent = "kCustomRequestUserAgent"
let AutoPlayGIFInGridKey = "kAutoPlayGIFInGridKey"
let AutoPlayGIFInPreviewKey = "kAutoPlayGIFInPreviewKey"
let ViewedTitlesKey = "kViewedTitles"
let IntelligentTorrentDownload = "kIntelligentTorrentDownload"
let PrefersMagnet = "kPrefersMagnet"
let TorrentKittenSource = "kTorrentKittenSource"
let DyttBaseAddress = "DyttBaseAddress"
let ViewedResources = "ViewedResourcesKey"
let LastCopiedMagnetsSHA256Key = "kLastCopiedMagnetsSHA256Key"

extension Notification.Name {
    static let viewedTitlesDidChangeNotification = Notification.Name(rawValue: "viewedTitlesDidChangeNotification")
}
