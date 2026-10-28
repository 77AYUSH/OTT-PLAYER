//
//  HomeFeedMapperTests.swift
//  OTTPlayerTests
//
//  Created by Ayush on 27/10/26.
//

import XCTest
@testable import OTTPlayer

final class HomeFeedMapperTests: XCTestCase {

    private let json = """
    {
      "hero": { "content_id": "b", "tagline": "" },
      "rails": [
        { "id": "r1", "title": "First", "content_ids": ["a", "missing", "b", "a"] },
        { "id": "r2", "title": "Only broken", "content_ids": ["broken"] },
        { "id": "r1", "title": "Duplicate rail id", "content_ids": ["a"] },
        { "id": "r3", "title": "Third", "content_ids": ["b"] }
      ],
      "contents": [
        {
          "id": "a", "title": "  Alpha ", "description": "Alpha description",
          "genre": "Drama", "release_year": 2001, "duration_seconds": 754,
          "thumbnail_url": "https://example.com/a.jpg", "banner_url": null,
          "video_url": "https://example.com/a.m3u8"
        },
        {
          "id": "b", "title": "Beta", "description": "Beta description",
          "thumbnail_url": "not a url",
          "video_url": "https://example.com/b.mp4"
        },
        { "id": "broken", "title": "No video", "description": "", "video_url": "ftp://nowhere" }
      ]
    }
    """

    func testMapsContentFieldsAndURLs() throws {
        let feed = HomeFeedMapper.map(try Fixtures.decode(json))
        let alpha = try XCTUnwrap(feed.content(withId: "a"))

        XCTAssertEqual(alpha.title, "Alpha", "titles are trimmed")
        XCTAssertEqual(alpha.genre, "Drama")
        XCTAssertEqual(alpha.releaseYear, 2001)
        XCTAssertEqual(alpha.duration, 754)
        XCTAssertEqual(alpha.videoURL, URL(string: "https://example.com/a.m3u8"))
        XCTAssertEqual(alpha.thumbnailURL, URL(string: "https://example.com/a.jpg"))
        XCTAssertEqual(alpha.bannerURL, alpha.thumbnailURL, "banner falls back to the thumbnail")

        let beta = try XCTUnwrap(feed.content(withId: "b"))
        XCTAssertNil(beta.thumbnailURL, "unparseable artwork URLs become nil so the cell shows a placeholder")
        XCTAssertNil(beta.genre)
    }

    func testRailsKeepOrderAndDropInvalidEntries() throws {
        let feed = HomeFeedMapper.map(try Fixtures.decode(json))

        XCTAssertEqual(feed.rails.map(\.id), ["r1", "r3"], "empty and duplicate rails are dropped")
        XCTAssertEqual(feed.rails[0].items.map(\.id), ["a", "b"], "unknown and repeated IDs are skipped, order kept")
        XCTAssertNil(feed.content(withId: "broken"), "content without a playable URL never reaches the domain")
    }

    func testRailStyleDefaultsToStandardAndRecognisesCarousel() throws {
        let dto = try Fixtures.decode("""
        { "rails": [
            { "id": "plain", "title": "Plain", "content_ids": ["x"] },
            { "id": "big", "title": "Big", "style": "Carousel", "content_ids": ["x"] },
            { "id": "odd", "title": "Odd", "style": "spiral", "content_ids": ["x"] }
          ],
          "contents": [{ "id": "x", "title": "X", "description": "", "video_url": "https://example.com/x.mp4" }] }
        """)
        let feed = HomeFeedMapper.map(dto)

        XCTAssertEqual(feed.rails.map(\.style), [.standard, .carousel, .standard], "unknown styles fall back to standard")
    }

    func testDurationFormatsAsTimecode() {
        XCTAssertEqual(TimeInterval(52).timecodeText, "0:52")
        XCTAssertEqual(TimeInterval(734).timecodeText, "12:14")
        XCTAssertEqual(TimeInterval(3900).timecodeText, "1:05:00")
        XCTAssertNil(TimeInterval(0).timecodeText)
    }

    func testHeroResolvesContentAndFallsBackToDescription() throws {
        let feed = HomeFeedMapper.map(try Fixtures.decode(json))

        XCTAssertEqual(feed.hero?.content.id, "b")
        XCTAssertEqual(feed.hero?.tagline, "Beta description")
    }

    func testHeroPointingAtUnknownContentIsDropped() throws {
        let dto = try Fixtures.decode("""
        { "hero": { "content_id": "nope" }, "rails": [], "contents": [] }
        """)
        let feed = HomeFeedMapper.map(dto)

        XCTAssertNil(feed.hero)
        XCTAssertTrue(feed.isEmpty)
    }

    func testMalformedPayloadThrowsDecodingFailed() {
        XCTAssertThrowsError(try Fixtures.decode(#"{ "rails": "oops" }"#)) { error in
            XCTAssertEqual(error as? NetworkError, .decodingFailed)
        }
    }
}
