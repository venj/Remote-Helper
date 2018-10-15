//
//  NSString+MD5.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation
import CommonCrypto

// via https://github.com/mnbayan/StringHash

extension String {
    var md5: String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)

        CC_MD5(str!, strLen, result);

        var hash = ""
        for i in 0 ..< digestLen {
            hash += String(format:"%02x", arguments:[result[i]])
        }
        //result.deinitialize()
        result.deallocate()

        return hash
    }
}
