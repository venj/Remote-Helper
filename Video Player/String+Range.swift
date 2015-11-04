//
//  String+Range.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

extension String {
    func rangeFromNSRange(range : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(range.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(range.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
}