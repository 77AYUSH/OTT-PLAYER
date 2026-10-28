//
//  HomeFeedResponseDTO.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

struct HomeFeedResponseDTO: Decodable {
    let hero: HeroDTO?
    let rails: [RailDTO]
    let contents: [ContentDTO]
}

struct HeroDTO: Decodable {
    let contentId: String
    let tagline: String?
}

struct RailDTO: Decodable {
    let id: String
    let title: String
    // "carousel" or nil
    let style: String?
    let contentIds: [String]
}

struct ContentDTO: Decodable {
    let id: String
    let title: String
    let description: String
    let genre: String?
    let releaseYear: Int?
    let durationSeconds: Double?
    let thumbnailUrl: String?
    let bannerUrl: String?
    let videoUrl: String
}
