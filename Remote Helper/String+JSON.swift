//
//  NSString+JSON.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@available(iOS 5.0, OSX 10.7, *)
public extension String {
    func JSONObject(_ encoding: String.Encoding = String.Encoding.utf8) -> Any? {
        guard let data = self.data(using: encoding) else { return nil }
        guard let JSON = try? JSONSerialization.jsonObject(with: data, options:[]) else { return nil }
        return JSON as Any?
    }
}
