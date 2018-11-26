//
//  SearchPage.swift
//  Remote Helper
//
//  Created by 朱文杰 on 2018/11/26.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import Kanna
import Darwin.POSIX.iconv

class SearchPage: Page {

    override class func parse(data: Data, pageLink: String, isGBK: Bool = false) -> SearchPage? {
        guard let html = isGBK ? (data as NSData).convertToUTF8String(fromEncoding: "GBK", allowLoosy: true) : String(data: data, encoding: .utf8) else { return nil }
        var bangumiLinks: [[String: String]] = []
        var nextPageLink: String? = nil
        do {
            // get bangumi links
            let replaced = html.replacingOccurrences(of: "charset=gb2312", with: "charset=utf-8")
            let doc = try HTML(html: replaced, encoding: .utf8)
            doc.css("div.co_content8 table td a").forEach({ (element) in
                var bangumiLink: [String: String] = [:]
                guard let link = element["href"] else { return }
                if link.contains("index.html") || String(link.last!) == "/" { return }
                let title = element.text ?? ""
                bangumiLink["title"] = title
                bangumiLink["link"] = link
                if title.count <= 3 { return }
                bangumiLinks.append(bangumiLink)
            })
            // get next page
            doc.css("div.co_content8 table td a").forEach({ (element) in
                if element.text == "下一页" {
                    guard let link = element["href"] else { return }
                    let url = URL(string: pageLink)!
                    nextPageLink = url.scheme! + "://" + url.host! + "/" + link
                }
            })

        } catch let error {
            print(error.localizedDescription)
        }

        let page = SearchPage(pageLink: pageLink, bangumiLinks: bangumiLinks, nextPageLink: nextPageLink)
        return page
    }
}

