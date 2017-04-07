//
//  NSDictionary+JSON.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/1.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@available(iOS 5.0, OSX 10.7, *)
public extension NSDictionary {
    var JSONString: String? {
        get {
            guard let data = self.JSONData else { return nil }
            return String(data: data, encoding: String.Encoding.utf8)
        }
    }

    var JSONData: Data? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else { return nil }
        return data
    }
}
