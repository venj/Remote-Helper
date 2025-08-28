//
//  CatResponse.swift
//  Remote Helper
//
//  Created by Venj Chu on 2023/6/5.
//  Copyright © 2023 Home. All rights reserved.
//

import Foundation

public struct CatResponse: Codable {
    var code: Int
    var message: String
    var data: CatResponseData
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decode(Int.self, forKey: .code)
        message = try values.decode(String.self, forKey: .message)
        data = try values.decode(CatResponseData.self, forKey: .data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
        try container.encode(data, forKey: .data)
    }
}
