//
//  HomeFeed.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

struct HomeHero: Hashable {
    let content: ContentItem
    let tagline: String
}

enum RailStyle: Hashable {
    case standard
    case carousel
}

struct ContentRail: Hashable {
    let id: String
    let title: String
    let style: RailStyle
    let items: [ContentItem]
}

struct HomeFeed: Equatable {
    let hero: HomeHero?
    let rails: [ContentRail]

    var isEmpty: Bool {
        hero == nil && rails.isEmpty
    }

    func content(withId id: String) -> ContentItem? {
        if hero?.content.id == id {
            return hero?.content
        }
        for rail in rails {
            if let item = rail.items.first(where: { $0.id == id }) {
                return item
            }
        }
        return nil
    }
}
