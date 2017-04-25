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
