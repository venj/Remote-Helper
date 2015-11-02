//
//  NSString+Regex.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@available(iOS 4.0, OSX 10.6, *)
public extension NSString {
    func arrayOfCaptureComponentsMatchedByRegex(pattern: String) -> [[String]] {
        var result: [[String]] = [[]]
        guard let regex = try? NSRegularExpression(pattern: pattern, options:[.CaseInsensitive]) else { return result }
        let matches = regex.matchesInString((self as String), options: [], range: self.rangeOfString(self as String))
        for match in matches {
            var subResult: [String] = []
            for var i = 0; i < match.numberOfRanges; ++i {
                let range = match.rangeAtIndex(i)
                subResult.append(self.substringWithRange(range))
            }
            result.append(subResult)
        }
        return result
    }
    
    func captureComponentsMatchedByRegex(pattern: String, capture captureIndex: Int = 0) -> [String] {
        let matches = self.arrayOfCaptureComponentsMatchedByRegex(pattern)
        var result: [String] = []
        for match in matches {
            guard captureIndex < match.count else { return result } // Make sure index not beyond length
            result.append(match[captureIndex])
        }
        return result
    }

    func stringByMatching(pattern: String, capture captureIndex: Int = 0) -> String? {
        let matches = self.arrayOfCaptureComponentsMatchedByRegex(pattern)
        var result: String? = nil
        for match in matches {
            guard captureIndex < match.count else { continue } // Make sure index not beyond length
            result = match[captureIndex]
            break
        }
        return result
    }
}