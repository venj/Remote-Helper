//
//  CatTorrent.swift
//  Remote Helper
//
//  Created by Venj Chu on 2023/6/5.
//  Copyright © 2023 Home. All rights reserved.
//

import Foundation

public enum CatSource: Int, CustomStringConvertible {
    case main = 0
    case sub

    public var description: String {
        switch self {
        case .main:
            return "NYN"
        case .sub:
            return "NYH"
        }
    }
}

public struct CatTorrent: Codable {
    var title: String
    var torrent: String
    var magnet: String
    var date: String
    var size: String
    var upload: String = "0"
    var download: String = "0"
    var finished: String = "0"

    var dateObject: Date {
        let defaultDate = Date().addingTimeInterval(-157680000) // Default to 5 years ago if string is not parsable.
        let c = date.components(separatedBy: "-")
        if c.count < 3 { return defaultDate }
        var dc = DateComponents()
        dc.year = Int(c[0]) ?? 2013
        dc.month = Int(c[1]) ?? 1
        dc.day = Int(c[2]) ?? 1
        return dc.date ?? defaultDate
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        torrent = try values.decode(String.self, forKey: .torrent)
        magnet = try values.decode(String.self, forKey: .magnet)
        date = try values.decode(String.self, forKey: .date)
        size = try values.decode(String.self, forKey: .size)
        upload = try values.decode(String.self, forKey: .upload)
        download = try values.decode(String.self, forKey: .download)
        finished = try values.decode(String.self, forKey: .finished)
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case torrent
        case magnet
        case date
        case size
        case maxPage
        case upload
        case download
        case finished
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(torrent, forKey: .torrent)
        try container.encode(magnet, forKey: .magnet)
        try container.encode(date, forKey: .date)
        try container.encode(size, forKey: .size)
        try container.encode(upload, forKey: .upload)
        try container.encode(download, forKey: .download)
        try container.encode(finished, forKey: .finished)
    }
}
