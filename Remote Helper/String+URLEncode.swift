//
//  NSString+URLEncode.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

public extension String {
    var percentEncodedString: String {
        get {
            return self.percentEncodedString() ?? self
        }
    }

    var decodedPercentEncodingString: String {
        get {
            let str = self.replacingOccurrences(of: "+", with: " ")
            guard let s = str.removingPercentEncoding else { return self }
            return s
        }
    }

    func percentEncodedString(_ encoding: String.Encoding = .utf8, toLowerCased: Bool = false) -> String? {
        if encoding == .utf8 {
            let rfc3986ReservedCharacterSet = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]")
            guard let str = self.addingPercentEncoding(withAllowedCharacters: rfc3986ReservedCharacterSet.inverted) else { return self }
            return str
        }
        else {
            guard let data = self.data(using: encoding) else { return nil }
            let result = data.map {
                return String(format: "%%%02X", $0)
            }.joined()

            return toLowerCased ? result.lowercased() : result.uppercased()
        }
    }
}
