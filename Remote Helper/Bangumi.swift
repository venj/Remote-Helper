//
//  Resource.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import Foundation
import Fuzi

struct Bangumi {
    var title: String
    var links: [String]
    var images: [String]
    var info: String

    static func parse(data: Data, isGBK: Bool = false) -> Bangumi? {
        guard let html = isGBK ? (data as NSData).convertToUTF8String(fromEncoding: "GBK", allowLoosy: true) : String(data: data, encoding: .utf8) else { return nil }
        do {
            let doc = try HTMLDocument(string: html)
            let title = doc.css("div.title_all h1").first?.stringValue ?? NSLocalizedString("Unknown Title", comment: "Unknown Title")
            var links: [String] = []
            doc.css("div.co_content8 table td a").forEach({ (element) in
                guard let link = element["href"] else { return }
                links.append(link)
            })

            var images: [String] = []
            doc.css("div.co_content8 div#Zoom p img").forEach { element in
                guard let src = element["src"] else { return }
                images.append(src)
            }

            var info = ""
            doc.css("div.co_content8 div#Zoom p").forEach { element in
                let rawXML = element.rawXML.replacingOccurrences(of: "<br>", with: "\n").replacingOccurrences(of: "\r", with: "")
                info += rawXML.replacingOccurrences(of: "<[^>]+?>", with: "", options: String.CompareOptions.regularExpression, range: rawXML.range(of: rawXML))
            }

            let bangumi = Bangumi(title: title, links: links, images: images, info: info)
            return bangumi
        } catch let error {
            print(error.localizedDescription)
        }

        return nil
    }
}
