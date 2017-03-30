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
    case thunder
    case qq
    case flashget
    case unknown
}

@objc
public enum URLConverterConvertError: Int, Error {
    case invalidURL
    case unknownScheme
}

@objc
open class URLConverter : NSObject {
    class func encode(_ urlString: String, type: URLConverterType) -> String {
        var template = "", scheme = ""
        switch type {
        case .thunder:
            template = "AA\(urlString)ZZ"
            scheme = "thunder"
        case .qq:
            template = urlString
            scheme = "qqdl"
        case .flashget:
            template = "[FLASHGET]\(urlString)[FLASHGET]"
            scheme = "Flashget"
        case .unknown: // Return original url string while type unknown
            return urlString
        }
        return "\(scheme)://" + (template.data(using: .utf8)?.base64EncodedString() ?? "")
    }

    class func decode(_ urlString: String) throws -> String {
        let components = urlString.components(separatedBy: "//")
        guard components.count == 2 else { throw URLConverterConvertError.invalidURL }

        var type:URLConverterType = .unknown
        if components[0].lowercased() == "thunder:" {
            type = .thunder
        }
        else if components[0].lowercased() == "qqdl:" {
            type = .qq
        }
        else if components[0].lowercased() == "flashget:" {
            type = .flashget
        }

        guard let decodedString = components[1].decodedBase64String() else { throw URLConverterConvertError.invalidURL }
        var pattern = ""
        switch type {
        case .thunder:
            pattern = "AA(.+?)ZZ"
        case .qq:
            return decodedString
        case .flashget:
            pattern = "[FLASHGET](.+?)[FLASHGET]"
        case .unknown: // Return original url string while type unknown
            throw URLConverterConvertError.unknownScheme
        }
        guard let url = decodedString.stringByMatching(pattern) else { throw URLConverterConvertError.invalidURL }
        return url
    }
}
