//
//  Int+FileSize.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/2.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

public extension Int {
    var gb: Int {
        return self * 1024 * 1024 * 1024
    }

    var mb: Int {
        return self * 1024 * 1024
    }

    var kb: Int {
        return self * 1024
    }

    var fileSizeString: String {
        var str = ""
        if self > 1.gb {
            str = String(format: "%.1f GB", arguments: [Double(self) / Double(1.gb)])
        }
        else if self > 1.mb {
            str = String(format: "%.1f MB", arguments: [Double(self) / Double(1.mb)])
        }
        else if self > 1.kb {
            str = String(format: "%.1f KB", arguments: [Double(self) / Double(1.kb)])
        }
        else {
            str = String(format: "%.1f MB", arguments: [Double(self)])
        }
        return str
    }
}
