//
//  KittenTorrent.swift
//  TestApp
//
//  Created by Venj Chu on 16/11/23.
//  Copyright © 2016年 VPNCloud. All rights reserved.
//

import Foundation
import Fuzi

struct KittenTorrent {
    var title: String
    var magnet: String
    var date: String
    var size: String
    var maxPage: Int = 1

    static func parse(data: Data) -> [KittenTorrent] {
        var results : [KittenTorrent] = []

        do {
            let doc = try HTMLDocument(data: data)

            var page = 1
            doc.css("div.pagination a").forEach {
                let pageString = $0.stringValue
                let i = Int(pageString) ?? page
                if page < i {
                    page = i
                }
            }

            for row in doc.css("#archiveResult tr") {
                guard let title = row.css("td.name") .first?.stringValue else { continue }
                let size = row.css("td.size") .first?.stringValue ??  ""
                let date = row.css("td.date") .first?.stringValue ??  ""
                let magnet = row.css("td.action a").filter{ $0.attr("rel") == "magnet" }.first?.attr("href") ?? ""
                let torrent = KittenTorrent(title: title, magnet: magnet, date: date, size: size, maxPage: page)
                results.append(torrent)
            }
        } catch let error {
            print(error.localizedDescription)
        }

        return results
    }

}
