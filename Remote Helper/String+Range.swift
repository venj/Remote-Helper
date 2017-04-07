//
//  String+Range.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

extension String {
    func range(from range : NSRange) -> Range<String.Index> {
        let from16 = utf16.startIndex.advanced(by: range.location)
        let to16 = from16.advanced(by: range.length)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
            return from ..< to
        }
        fatalError("Range conversion error")
    }
}
