//
//  ContentItem.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

struct ContentItem: Hashable {
    let id: String
    let title: String
    let description: String
    let genre: String?
    let releaseYear: Int?
    let duration: TimeInterval?
    let thumbnailURL: URL?
    let bannerURL: URL?
    let videoURL: URL
}
