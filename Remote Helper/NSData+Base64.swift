//
//  NSData+Base64.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@available(iOS 7.0, OSX 10.9, *)
public extension Data {
    static func dataWithBase64EncodedString(_ string: String) -> Data? {
        return self.init(base64Encoded: string, options: [])
    }

    func base64EncodedString() -> String {
        return self.base64EncodedString(options: [])
    }
}
