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
    func JSONObject(encoding: NSStringEncoding = NSUTF8StringEncoding) -> AnyObject? {
        guard let data = self.dataUsingEncoding(encoding) else { return nil }
        guard let JSON = try? NSJSONSerialization.JSONObjectWithData(data, options:[]) else { return nil }
        return JSON
    }
}
