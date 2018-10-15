//
//  Resource.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import Foundation
import Kanna

struct Bangumi {
    var title: String
    var links: [Link]
    var images: [String]
    var info: String

    init(title: String, links: [Link], images: [String], info: String) {
        self.title = title
        self.links = links
        self.images = images
        self.info = info
    }

    init(title: String, links: [Link]) {
        self.title = title
        self.links = links
        self.images = []
        self.info = ""
    }

    static func parse(data: Data, isGBK: Bool = false) -> Bangumi? {
        guard let html = isGBK ? (data as NSData).convertToUTF8String(fromEncoding: "GBK", allowLoosy: true) : String(data: data, encoding: .utf8) else { return nil }
        do {
            let replaced = html.replacingOccurrences(of: "charset=gb2312", with: "charset=utf-8")
            let doc = try HTML(html: replaced, encoding: .utf8)
            let title = doc.css("div.title_all h1").first?.text ?? NSLocalizedString("Unknown Title", comment: "Unknown Title")
            var links: [Link] = []
            doc.css("div.co_content8 table td a").forEach({ (element) in
                guard let link = element["href"] else { return }
                links.append(Link(link))
            })

            var images: [String] = []
            doc.css("div.co_content8 #Zoom img").forEach { element in
                guard let src = element["src"] else { return }
                images.append(src)
            }

            let info = doc.css("div.co_content8 #Zoom")
                .compactMap{$0.toXML}
                .joined()
                .replacingOccurrences(of: "<br>", with: "\n")
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: " +", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<[^>]+?>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)

            let bangumi = Bangumi(title: title, links: links, images: images, info: info)
            return bangumi
        } catch let error {
            print(error.localizedDescription)
        }

        return nil
    }
}
