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
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
}
