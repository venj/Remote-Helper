//
//  Constants.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/4.
//  Copyright © 2015 Home. All rights reserved.
//

let REQUEST_TIME_OUT = 10.0
let ServerHostKey = "kServerHostKey"
let ServerPortKey = "kServerPortKey"
let ServerPathKey = "kServerPathKey"
let TransmissionAddressKey = "kTransmissionAddressKey"
let TransmissionUserNameKey = "kTransmissionUserNameKey"
let TransmissionPasswordKey = "kTransmissionPasswordKey"
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
let ViewedTitlesKey = "kViewedTitles"

extension Notification.Name {
    static let viewedTitlesDidChangeNotification = Notification.Name(rawValue: "viewedTitlesDidChangeNotification")
}
