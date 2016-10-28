//
//  NSString+Path.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

extension String {
    func vc_stringByAppendingPathComponent(_ component: String) -> String {
        return self.vc_stringByAppendingPathComponents([component])
    }

    func vc_stringByAppendingPathComponents(_ components: [String]) -> String {
        guard var url = URL(string: self) else { return self }
        for component in components {
            url = url.appendingPathComponent(component)
        }
        return url.absoluteString
    }

    func vc_lastPathComponent() -> String {
        let url = URL(fileURLWithPath: self)
        let components = url.pathComponents
        guard components.count > 0 else { return self }
        return components.last!
    }
}
