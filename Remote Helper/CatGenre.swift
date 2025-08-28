//
//  CatGenre.swift
//  Remote Helper
//
//  Created by Venj Chu on 2023/6/5.
//  Copyright © 2023 Home. All rights reserved.
//

import Foundation

// TODO: Make it tree like
public struct CatGenre: Codable {
    var title: String
    var value: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case value
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        value = try values.decode(String.self, forKey: .value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(value, forKey: .value)
    }
}
