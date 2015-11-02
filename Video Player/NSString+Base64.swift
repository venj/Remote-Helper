//
//  NSString+Base64.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@available(iOS 7.0, OSX 10.9, *)
public extension NSString {
    func base64String() -> NSString? {
        guard let data = self.dataUsingEncoding(NSUTF8StringEncoding) else { return nil }
        return data.base64EncodedStringWithOptions([])
    }

    func decodedBase64String() -> NSString? {
        guard let data = NSData(base64EncodedString: (self as String), options: []) else { return nil }
        return NSString(data: data, encoding: NSUTF8StringEncoding)
    }
}
