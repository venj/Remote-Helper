//
//  FileAttributeHelper.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@available(iOS 5.1, *)
public class FileAttributeHelper {
    @objc
    class func haveSkipBackupAttributeForItemAtURL(url: NSURL) -> Bool {
        if NSFileManager.defaultManager().fileExistsAtPath(url.absoluteString) { return true } // Treat as true if file not exists.
        var result: AnyObject?
        do {
            try url.getResourceValue(&result, forKey: NSURLIsExcludedFromBackupKey)
            guard let _ = result else { return true }  // treat as true if result value is not set properly.
            return result!.boolValue
        }
        catch _ { return true } // Treat as true if read attributes error.
    }

    @objc
    class func addSkipBackupAttributeToItemAtURL(url: NSURL) -> Bool {
        if haveSkipBackupAttributeForItemAtURL(url) { return true }
        do {
            try url.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
        }
        catch _ {
            // do nothing if failed, just return true
            print("Error excluding \(url.lastPathComponent) from backup.")
        }
        return true
    }
}
