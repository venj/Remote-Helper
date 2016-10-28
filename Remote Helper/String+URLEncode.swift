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
            let rfc3986ReservedCharacterSet = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]")
            guard let str = self.addingPercentEncoding(withAllowedCharacters: rfc3986ReservedCharacterSet.inverted) else { return self }
            return str
        }
    }

    var decodedPercentEncodingString: String {
        get {
            let str = self.replacingOccurrences(of: "+", with: " ")
            guard let s = str.removingPercentEncoding else { return self }
            return s
        }
    }
}
