//
//  RemoteMedia.swift
//  Demo
//
//  Created by jxing on 2025/10/28.
//

import Foundation

struct RemoteMedia {
    let id: UUID
    let source: SourceType
    let referer: String?

    init(source: SourceType, referer: String? = nil) {
        self.id = UUID()
        self.source = source
        self.referer = referer
    }

    enum SourceType {
        case remoteImage(imageURL: URL, thumbnailURL: URL?)
        case remoteVideo(url: URL, thumbnailURL: URL)
    }
}
