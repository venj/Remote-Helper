//
//  NSString+Base64.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@available(iOS 7.0, OSX 10.9, *)
public extension String {
    func base64String() -> String? {
        guard let data = self.dataUsingEncoding(NSUTF8StringEncoding) else { return nil }
        return data.base64EncodedStringWithOptions([])
    }

    func decodedBase64String() -> String? {
        guard let data = NSData(base64EncodedString: self, options: []) else { return nil }
        let result = String(data: data, encoding: NSUTF8StringEncoding)
        if result != nil { // UTF-8.
            return result
        }
        else { // GBK. Damn it!
            let cfgb18030encoding = CFStringEncodings.GB_18030_2000.rawValue
            let gbkEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfgb18030encoding))
            return String(data: data, encoding: gbkEncoding)
        }
    }
}
