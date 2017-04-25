//
//  DispatchQueueExtension.swift
//  Remote Helper
//
//  Created by Zhu Wen Jie on 17/1/12.
//  Copyright © 2017 Remote Helper. All rights reserved.
//

import Foundation

extension DispatchQueue {
    // Copy from Alamofire
    func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
