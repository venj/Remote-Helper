//
//  NSString+URLEncode.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

public extension String {
    var percentEncodedString: String {
        get {
            let rfc3986ReservedCharacterSet = NSCharacterSet(charactersInString: "!*'();:@&=+$,/?%#[]")
            guard let str = self.stringByAddingPercentEncodingWithAllowedCharacters(rfc3986ReservedCharacterSet.invertedSet) else { return self }
            return str
        }
    }

    var decodedPercentEncodingString: String {
        get {
            let str = self.stringByReplacingOccurrencesOfString("+", withString: " ")
            guard let s = str.stringByRemovingPercentEncoding else { return self }
            return s
        }
    }
}
