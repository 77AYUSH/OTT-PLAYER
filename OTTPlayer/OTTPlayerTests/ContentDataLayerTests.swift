//
//  ContentDataLayerTests.swift
//  OTTPlayerTests
//
//  Created by Ayush on 27/10/26.
//

import XCTest
@testable import OTTPlayer

final class ContentDataLayerTests: XCTestCase {

    func testBundledHomeFeedDecodesIntoUsableFeed() async throws {
        let dataSource = StaticHomeFeedDataSource(fileName: "home_feed", bundle: Bundle(for: AppDelegate.self))
        let feed = HomeFeedMapper.map(try await dataSource.fetchHomeFeed())

        XCTAssertNotNil(feed.hero)
        XCTAssertGreaterThanOrEqual(feed.rails.count, 2)
        XCTAssertTrue(feed.rails.allSatisfy { !$0.items.isEmpty })
    }

    func testMissingFileThrowsFileNotFound() async {
        let dataSource = StaticHomeFeedDataSource(fileName: "does_not_exist", bundle: Bundle(for: AppDelegate.self))
        do {
            _ = try await dataSource.fetchHomeFeed()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .fileNotFound(name: "does_not_exist"))
        }
    }

    func testRepositoryResolvesContentFromCachedFeed() async throws {
        let dataSource = StubHomeFeedDataSource(response: try Fixtures.decode("""
        { "rails": [{ "id": "r", "title": "R", "content_ids": ["x"] }],
          "contents": [{ "id": "x", "title": "X", "description": "", "video_url": "https://example.com/x.mp4" }] }
        """))
        let repository = DefaultContentRepository(dataSource: dataSource)

        _ = try await repository.fetchHomeFeed()
        let item = try await repository.fetchContent(id: "x")

        XCTAssertEqual(item.title, "X")
        XCTAssertEqual(dataSource.fetchCount, 1, "detail lookups reuse the feed already loaded")
    }

    func testRepositoryThrowsNotFoundForUnknownId() async throws {
        let dataSource = StubHomeFeedDataSource(response: try Fixtures.decode(#"{ "rails": [], "contents": [] }"#))
        let repository = DefaultContentRepository(dataSource: dataSource)

        do {
            _ = try await repository.fetchContent(id: "ghost")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? ContentError, .notFound(id: "ghost"))
        }
    }
}
