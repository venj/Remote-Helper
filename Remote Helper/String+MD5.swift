//
//  NSString+MD5.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation
import CryptoKit

// via https://github.com/mnbayan/StringHash

extension String {
    var md5: String {
        guard let str = self.cString(using: .utf8) else { return "" }
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)

        RH_CC_MD5(str, strLen, result)

        var hash = ""
        for i in 0 ..< digestLen {
            hash += String(format:"%02x", arguments:[result[i]])
        }
        //result.deinitialize()
        result.deallocate()

        return hash
    }

    var sha256: String {
        if #available(iOS 13.0, macOS 10.15, *) {
            guard let data = self.data(using: .utf8) else { return "" }
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            return self.md5 // Fallback if needed, but not required since app relies on iOS 13+ SceneDelegate
        }
    }
}
