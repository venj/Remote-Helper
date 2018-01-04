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
        let t = Link.processLink(target)
        self.name = t.humanReadableFileName()
        self.target = t
    }

    init(name: String, target: String) {
        let t = Link.processLink(target)
        self.name = name.isEmpty ? t.humanReadableFileName() : name
        self.target = t
    }

    private static func processLink(_ link: String) -> String {
        let loLink = link.lowercased()
        if (loLink.hasPrefix("qqdl://")
            || loLink.lowercased().hasPrefix("thunder://")
            || loLink.lowercased().hasPrefix("flashget://"))
            && loLink.decodedLink?.hasPrefix("magnet:") == true {
            return link.decodedLink!
        }
        else {
            return link
        }
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
        return target.hasPrefix("magnet:?")
    }
}
