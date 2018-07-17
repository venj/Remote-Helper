//
//  KittenTorrent.swift
//  TestApp
//
//  Created by Venj Chu on 16/11/23.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import Fuzi

public enum KittenSource: Int, CustomStringConvertible {
    case main = 0
    case bt177

    public var description: String {
        switch self {
        case .main:
            return "TorrentKitty"
        default:
            return "BT177"
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
        case .bt177:
            if dateString == "今天" {
                return Date()
            }
            else if dateString == "昨天" {
                return Date.init(timeIntervalSinceNow: -86400)
            }
            else if dateString.contains("天前") {
                let day = Int(dateString.replacingOccurrences(of: "天前", with: ""))!
                return Date.init(timeIntervalSinceNow: Double(-86400 * day))
            }
            else if dateString.contains("个月前") {
                let month = Int(dateString.replacingOccurrences(of: "个月前", with: ""))!
                return Date.init(timeIntervalSinceNow: Double(-86400 * 30 * month))
            }
            else if dateString.contains("年前") {
                let month = Int(dateString.replacingOccurrences(of: "年前", with: ""))!
                return Date.init(timeIntervalSinceNow: Double(-86400 * 365 * month))
            }
            else {
                return defaultDate
            }
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
            let doc = try HTMLDocument(data: data)
            var page = 1

            switch source {
            case .bt177:
                let numberOfItemsPerPage = 10.0
                let itemsCount = Double(doc.css("#container .tips span.number")[0].stringValue) ?? 1
                var page = Int(ceil(itemsCount / numberOfItemsPerPage))
                if page > 100 { page = 100 } // Max to 100 pages else 500 error.
                for row in doc.css("#container .main ul.mlist li") {
                    guard let title = row.css(".T1 a").first?.stringValue else { continue }
                    // Filter based on ad black list.
                    if Helper.shared.kittenBlackList.filter({ title.contains($0) }).count > 0 { continue }
                    // Filter out no result
                    if title.contains("No result - ") { continue }
                    let size = row.css(".BotInfo dt span")[0].stringValue
                    let dateString = row.css(".BotInfo dt span")[1].stringValue
                    guard let magnetContent = row.css(".dInfo").first?.stringValue else { continue }
                    let magnet = magnetContent.replacingOccurrences(of: "HASH值：\\s*", with: "magnet:?xt=urn:btih:", options: [.caseInsensitive, .regularExpression], range: Range.init(NSRange(location: 0, length: magnetContent.count), in: magnetContent))
                    let torrent = KittenTorrent(title: title, magnet: magnet, dateString: dateString, size: size, maxPage: page, source: source)
                    results.append(torrent)
                }
            default: // 0 or other
                doc.css("div.pagination a").forEach {
                    let pageString = $0.stringValue
                    let i = Int(pageString) ?? page
                    if page < i {
                        page = i
                    }
                }

                for row in doc.css("#archiveResult tr") {
                    guard let title = row.css("td.name") .first?.stringValue else { continue }
                    // Filter based on ad black list.
                    if Helper.shared.kittenBlackList.filter({ title.contains($0) }).count > 0 { continue }
                    // Filter out no result
                    if title.contains("No result - ") { continue }
                    let size = row.css("td.size") .first?.stringValue ??  ""
                    let dateString = row.css("td.date") .first?.stringValue ??  ""
                    let magnet = row.css("td.action a").filter{ $0.attr("rel") == "magnet" }.first?.attr("href") ?? ""
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
