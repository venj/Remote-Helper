//
//  Configuration.swift
//  Remote Helper
//
//  Created by venj on 2017/12/12.
//  Copyright © 2017年 Home. All rights reserved.
//

import Foundation

open class Configuration {

    let ViewedResources = "ViewedResourcesKey"

    open static let shared = Configuration()
    private let defaults = UserDefaults.standard
    private init() {
        defaults.register(defaults: [ViewedResources: []])
        defaults.synchronize()
    }

    open var hasTorrentServer: Bool {
        get {
            // Treat any string less than 5 chars as invalid address.
            if let server = defaults.object(forKey: ServerHostKey) as? String, server.count >= 5 {
                return true
            }
            return false
        }
    }

    open var viewedResources: [String] {
        get {
            return defaults.array(forKey: ViewedResources) as? [String] ?? []
        }
        set {
            defaults.set(newValue, forKey: ViewedResources)
            defaults.synchronize()
        }
    }
}
