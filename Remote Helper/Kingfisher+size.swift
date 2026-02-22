//
//  Kingfisher+size.swift
//  Remote Helper
//
//  Created by venj on 11/3/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Kingfisher
import Atomics

extension ImageCache {
    var usedSize: UInt {
        let result = ManagedAtomic<UInt>(0)
        let sema = DispatchSemaphore(value: 0)
        calculateDiskStorageSize { r in
            result.store((try? r.get()) ?? 0, ordering: .relaxed)
            sema.signal()
        }
        _ = sema.wait(timeout: DispatchTime.distantFuture)
        return result.load(ordering: .relaxed)
    }
}
