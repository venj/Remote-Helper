//
//  DispatchQueueExtension.swift
//  VPNCloud
//
//  Created by Zhu Wen Jie on 17/1/12.
//  Copyright © 2017 VPNCloud. All rights reserved.
//

import Foundation

extension DispatchQueue {
    // Copy from Alamofire
    func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
