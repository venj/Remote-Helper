//
//  KittenTorrent.swift
//  TestApp
//
//  Created by Venj Chu on 16/11/23.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import SwiftSoup

public enum KittenSource: Int, CustomStringConvertible {
    case main = 0
    case sub

    public var description: String {
        switch self {
        case .main:
            return "NYH"
        case .sub:
            return "NY"
        }
    }
}

public struct KittenTorrent {
    var title: String
    var magnet: String
    var dateString: String
    var size: String
    var maxPage: Int = 1
    var source: KittenSource = .main // Can change source
    var date: Date {
        let defaultDate = Date().addingTimeInterval(-157680000) // Default to 5 years ago if string is not parsable.
        switch source {
        default:
            let c = dateString.components(separatedBy: "-")
            if c.count < 3 { return defaultDate }
            var dc = DateComponents()
            dc.year = Int(c[0]) ?? 2013
            dc.month = Int(c[1]) ?? 1
            dc.day = Int(c[2]) ?? 1
            return dc.date ?? defaultDate
        }
    }

    static func parse(data: Data, source: KittenSource = .main) -> [KittenTorrent] {
        var results : [KittenTorrent] = []

        do {
            let doc = try SwiftSoup.parse(String(data: data, encoding: .utf8) ?? "")
            var page = 1

            switch source {
            default:
                try doc.select("ul.pagination a").forEach {
                    let pageString = (try? $0.text()) ?? ""
                    let i = Int(pageString) ?? page
                    if page < i {
                        page = i
                    }
                }

                for row in try doc.select(".torrent-list tr.default") {
                    let tds = try row.select("td")
                    guard let title = try? tds[1].text() else { continue }
                    let size = (try? tds[3].text()) ??  ""
                    let dateString = (try? tds[4].text()) ??  ""
                    let magnet = try tds[2].select("a").map { (a) in try a.attr("href") }.filter { s in s.hasPrefix("magnet:?xt=urn:btih:") }.first ?? ""
                    let torrent = KittenTorrent(title: title, magnet: magnet, dateString: dateString, size: size, maxPage: page, source: source)
                    results.append(torrent)
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }

        return results
    }

}
