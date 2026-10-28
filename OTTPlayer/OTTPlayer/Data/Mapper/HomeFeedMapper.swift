//
//  HomeFeedMapper.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

enum HomeFeedMapper {

    static func map(_ response: HomeFeedResponseDTO) -> HomeFeed {
        var catalogue: [String: ContentItem] = [:]
        for contentDTO in response.contents {
            guard let item = map(contentDTO) else {
                AppLogger.data.warning("Skipping content \(contentDTO.id, privacy: .public): missing title or invalid video URL")
                continue
            }
            if catalogue[item.id] == nil {
                catalogue[item.id] = item
            }
        }

        var seenRailIds = Set<String>()
        let rails: [ContentRail] = response.rails.compactMap { railDTO in
            guard seenRailIds.insert(railDTO.id).inserted else { return nil }

            var seenContentIds = Set<String>()
            let items: [ContentItem] = railDTO.contentIds.compactMap { contentId in
                guard seenContentIds.insert(contentId).inserted else { return nil }
                guard let item = catalogue[contentId] else {
                    AppLogger.data.warning("Rail \(railDTO.id, privacy: .public) references unknown content \(contentId, privacy: .public)")
                    return nil
                }
                return item
            }
            guard !items.isEmpty else { return nil }
            let style: RailStyle = railDTO.style?.lowercased() == "carousel" ? .carousel : .standard
            return ContentRail(id: railDTO.id, title: railDTO.title, style: style, items: items)
        }

        let hero: HomeHero? = response.hero.flatMap { heroDTO in
            guard let content = catalogue[heroDTO.contentId] else { return nil }
            let tagline = heroDTO.tagline.flatMap { $0.isEmpty ? nil : $0 } ?? content.description
            return HomeHero(content: content, tagline: tagline)
        }

        return HomeFeed(hero: hero, rails: rails)
    }

    static func map(_ dto: ContentDTO) -> ContentItem? {
        let title = dto.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dto.id.isEmpty, !title.isEmpty, let videoURL = webURL(from: dto.videoUrl) else {
            return nil
        }
        return ContentItem(
            id: dto.id,
            title: title,
            description: dto.description,
            genre: dto.genre,
            releaseYear: dto.releaseYear,
            duration: dto.durationSeconds,
            thumbnailURL: webURL(from: dto.thumbnailUrl),
            bannerURL: webURL(from: dto.bannerUrl) ?? webURL(from: dto.thumbnailUrl),
            videoURL: videoURL
        )
    }

    private static func webURL(from string: String?) -> URL? {
        guard let string, let url = URL(string: string),
              let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
              url.host != nil else {
            return nil
        }
        return url
    }
}
