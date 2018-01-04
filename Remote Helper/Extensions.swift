//
//  Extensions.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation

extension Data {
    func stringFromGB18030Data() -> String? {
        // CP 936: GBK, CP 54936: GB18030
        //let cfEncoding = CFStringConvertWindowsCodepageToEncoding(54936) //GB18030
        let cfgb18030encoding = CFStringEncodings.GB_18030_2000.rawValue
        let gbkEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfgb18030encoding))
        
        return String(data: self, encoding: String.Encoding(rawValue: gbkEncoding))
    }
}

extension String {
    func humanReadableFileName() -> String {
        guard let decodedLink = removingPercentEncoding else { return self }
        let protocal = decodedLink.components(separatedBy: ":")[0].lowercased()
        if protocal == "thunder" || protocal == "flashget" || protocal == "qqdl" {
            guard let decodedThunderLink = try? URLConverter.decode(self) else { return decodedLink }
            guard let result = decodedThunderLink.removingPercentEncoding else { return decodedThunderLink }
            return result.humanReadableFileName()
        }
        else if protocal == "magnet" {
            guard let queryString = decodedLink.components(separatedBy: "?").last else { return decodedLink }
            let kvs = queryString.replacingOccurrences(of: "&amp;", with: "&").components(separatedBy: "&")
            var name = decodedLink
            for kv in kvs {
                let kvPair = kv.components(separatedBy: "=")
                if (kvPair[0].lowercased() == "dn" || kvPair[0].lowercased() == "btname") && kvPair[1] != "" {
                    name = kvPair[1].replacingOccurrences(of: "+", with: " ")
                    break
                }
            }
            return name
        }
        else if protocal == "ed2k" {
            let parts = decodedLink.components(separatedBy: "|")
            let index: Int? = parts.index(of: "file")
            if index != nil && parts.count > index! + 2 {
                return parts[index! + 1]
            }
            else {
                return decodedLink
            }
        }
        else if protocal == "ftp" || protocal == "http" || protocal == "https" {
            guard let result = decodedLink.components(separatedBy: "/").last else { return decodedLink }
            return result
        }
        else {
            return decodedLink
        }
    }

    var decodedLink: String? {
        return (try? URLConverter.decode(self))
    }
}
