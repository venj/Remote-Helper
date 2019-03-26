//
//  Kingfisher+size.swift
//  Remote Helper
//
//  Created by venj on 11/3/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Kingfisher

extension ImageCache {
    var usedSize: UInt {
        var result: UInt = 0
        let sema = DispatchSemaphore(value: 1)
        ImageCache.default.calculateDiskStorageSize { (r) in
            result = (try? r.get()) ?? 0
            sema.signal()
        }
        _ = sema.wait(timeout: DispatchTime.distantFuture)
        return result
    }
}
