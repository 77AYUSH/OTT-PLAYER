//
//  DefaultContentRepository.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

actor DefaultContentRepository: ContentRepository {

    private let dataSource: HomeFeedDataSource
    private var cachedFeed: HomeFeed?

    init(dataSource: HomeFeedDataSource) {
        self.dataSource = dataSource
    }

    func fetchHomeFeed() async throws -> HomeFeed {
        let response = try await dataSource.fetchHomeFeed()
        let feed = HomeFeedMapper.map(response)
        cachedFeed = feed
        return feed
    }

    func fetchContent(id: String) async throws -> ContentItem {
        let feed: HomeFeed
        if let cachedFeed {
            feed = cachedFeed
        } else {
            feed = try await fetchHomeFeed()
        }
        guard let item = feed.content(withId: id) else {
            throw ContentError.notFound(id: id)
        }
        return item
    }
}
