//
//  CatResponseData.swift
//  Remote Helper
//
//  Created by Venj Chu on 2023/6/5.
//  Copyright © 2023 Home. All rights reserved.
//

import Foundation

public struct CatResponseData: Codable {
    var contents: [CatTorrent]
    var page: Int
    var total: Int
    var genres: [CatGenre]
    
    enum CodingKeys: String, CodingKey {
        case contents
        case page
        case total
        case genres
    }
    
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        contents = try values.decode([CatTorrent].self, forKey: .contents)
        page = try values.decode(Int.self, forKey: .page)
        total = try values.decode(Int.self, forKey: .total)
        genres = try values.decode([CatGenre].self, forKey: .genres)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contents, forKey: .contents)
        try container.encode(page, forKey: .page)
        try container.encode(total, forKey: .total)
        try container.encode(genres, forKey: .genres)
    }
}
