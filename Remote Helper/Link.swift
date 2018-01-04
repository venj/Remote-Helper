//
//  Link.swift
//  Remote Helper
//
//  Created by venj on 1/4/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

struct Link {
    var name: String
    var target: String

    init(_ target: String) {
        if (target.lowercased().hasPrefix("qqdl://")
            || target.lowercased().hasPrefix("thunder://")
            || target.lowercased().hasPrefix("flashget://"))
            && target.decodedLink?.hasPrefix("magnet:") == true {
            self.target = target.decodedLink!
        }
        else {
            self.target = target
        }
        name = target.humanReadableFileName()
    }

    init(name: String, target: String) {
        self.name = name
        self.target = target
    }
}

extension Link : Hashable {
    var hashValue: Int {
        return target.hashValue & name.hashValue
    }

    static func ==(lhs: Link, rhs: Link) -> Bool {
        return lhs.name == rhs.name && lhs.target == rhs.target
    }
}

extension Link {
    var isMagnet: Bool {
        return target.hasPrefix("magnet:")
    }
}
