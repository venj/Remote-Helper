//
//  Page.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import Foundation
import SwiftSoup
import Darwin.POSIX.iconv

class Page {
    var pageLink: String
    var bangumiLinks: [[String: String]]
    var nextPageLink: String?
    var isLastPage: Bool {
        get {
            return (nextPageLink == nil)
        }
    }

    init(pageLink: String, bangumiLinks: [[String: String]], nextPageLink: String?) {
        self.pageLink = pageLink
        self.bangumiLinks = bangumiLinks
        self.nextPageLink = nextPageLink
    }

    class func parse(data: Data, pageLink: String, isGBK: Bool = false) -> Page? {
        guard let html = isGBK ? (data as NSData).convertToUTF8String(fromEncoding: "GBK", allowLoosy: true) : String(data: data, encoding: .utf8) else { return nil }
        var bangumiLinks: [[String: String]] = []
        var nextPageLink: String? = nil
        do {
            // get bangumi links
            let replaced = html.replacingOccurrences(of: "charset=gb2312", with: "charset=utf-8")
            let doc = try SwiftSoup.parse(replaced) // HTML(html: replaced, encoding: .utf8)
            try doc.select("div.co_content8 table td a.ulink").forEach({ (element) in
                var bangumiLink: [String: String] = [:]
                let link = try element.attr("href")
                if link.contains("index.html") || link.last == "/" { return }
                let title = try element.text()
                bangumiLink["title"] = title
                bangumiLink["link"] = link
                bangumiLinks.append(bangumiLink)
            })
            // get next page
            try doc.select("div.x a").forEach({ (element) in
                if try element.text() == "下一页" {
                    let link = try element.attr("href")
                    let url = URL(string: pageLink)!
                    if link.first != "/" {
                        nextPageLink = url.deletingLastPathComponent().appendingPathComponent(link).absoluteString
                    }
                    else {
                        nextPageLink = url.scheme! + "://" + url.host! + "/" + link
                    }
                }
            })

        } catch let error {
            print(error.localizedDescription)
        }

        let page = Page(pageLink: pageLink, bangumiLinks: bangumiLinks, nextPageLink: nextPageLink)
        return page
    }
}

