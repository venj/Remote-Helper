//
//  URLConverter.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@objc
public enum URLConverterType: Int {
    case Thunder
    case QQ
    case Flashget
    case Unknown
}

@objc
public enum URLConverterConvertError: Int, ErrorType {
    case InvalidURL
    case UnknownScheme
}

@objc
public class URLConverter : NSObject {
    class func encode(urlString: String, type: URLConverterType) -> String {
        var template = "", scheme = ""
        switch type {
        case .Thunder:
            template = "AA\(urlString)ZZ"
            scheme = "thunder"
        case .QQ:
            template = urlString
            scheme = "qqdl"
        case .Flashget:
            template = "[FLASHGET]\(urlString)[FLASHGET]"
            scheme = "Flashget"
        case .Unknown: // Return original url string while type unknown
            return urlString
        }
        return "\(scheme)://\(template.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedString())"
    }

    class func decode(urlString: String) throws -> String {
        let components = urlString.componentsSeparatedByString("//")
        guard components.count == 2 else { throw URLConverterConvertError.InvalidURL }

        var type:URLConverterType = .Unknown
        if components[0].lowercaseString == "thunder:" {
            type = .Thunder
        }
        else if components[0].lowercaseString == "qqdl:" {
            type = .QQ
        }
        else if components[0].lowercaseString == "flashget:" {
            type = .Flashget
        }

        guard let decodedString = components[1].decodedBase64String() else { throw URLConverterConvertError.InvalidURL }
        var pattern = ""
        switch type {
        case .Thunder:
            pattern = "AA(.+?)ZZ"
        case .QQ:
            return decodedString as String
        case .Flashget:
            pattern = "[FLASHGET](.+?)[FLASHGET]"
        case .Unknown: // Return original url string while type unknown
            throw URLConverterConvertError.UnknownScheme
        }
        guard let url = decodedString.stringByMatching(pattern) else { throw URLConverterConvertError.InvalidURL }
        return url
    }
}
