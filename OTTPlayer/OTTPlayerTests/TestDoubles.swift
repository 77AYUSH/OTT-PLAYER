//
//  TestDoubles.swift
//  OTTPlayerTests
//
//  Created by Ayush on 27/10/26.
//

import AVFoundation
import Foundation
@testable import OTTPlayer

enum Fixtures {

    static func content(id: String = "c1", title: String = "Title") -> ContentItem {
        ContentItem(
            id: id,
            title: title,
            description: "Description of \(title)",
            genre: "Drama",
            releaseYear: 2020,
            duration: 600,
            thumbnailURL: URL(string: "https://example.com/\(id).jpg"),
            bannerURL: URL(string: "https://example.com/\(id)-wide.jpg"),
            videoURL: URL(string: "https://example.com/\(id).m3u8")!
        )
    }

    static func feed(railCount: Int = 2) -> HomeFeed {
        let items = [content(id: "a", title: "A"), content(id: "b", title: "B")]
        let rails = (0..<railCount).map { ContentRail(id: "rail-\($0)", title: "Rail \($0)", style: .standard, items: items) }
        return HomeFeed(hero: HomeHero(content: items[0], tagline: "Tagline"), rails: rails)
    }

    static func decode(_ json: String) throws -> HomeFeedResponseDTO {
        try JsonHelper.decode(HomeFeedResponseDTO.self, from: Data(json.utf8))
    }
}

// the delay ignores cancellation on purpose, the view model has to drop stale results itself
final class StubFetchHomeFeedUseCase: FetchHomeFeedUseCase {

    struct Response {
        let result: Result<HomeFeed, Error>
        let delay: TimeInterval
    }

    private let lock = NSLock()
    private var responses: [Response]
    private var calls = 0

    init(responses: [Response]) {
        self.responses = responses
    }

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return calls
    }

    func execute() async throws -> HomeFeed {
        let response = nextResponse()
        if response.delay > 0 {
            await withCheckedContinuation { continuation in
                DispatchQueue.global().asyncAfter(deadline: .now() + response.delay) {
                    continuation.resume()
                }
            }
        }
        return try response.result.get()
    }

    private func nextResponse() -> Response {
        lock.lock()
        defer { lock.unlock() }
        calls += 1
        return responses.removeFirst()
    }
}

final class StubHomeFeedDataSource: HomeFeedDataSource {
    var response: HomeFeedResponseDTO
    private(set) var fetchCount = 0

    init(response: HomeFeedResponseDTO) {
        self.response = response
    }

    func fetchHomeFeed() async throws -> HomeFeedResponseDTO {
        fetchCount += 1
        return response
    }
}

final class SpyPlayerEventRepository: PlayerEventRepository {
    private(set) var events: [PlayerEvent] = []

    func record(_ event: PlayerEvent) {
        events.append(event)
    }
}

@MainActor
final class FakePlayerEventHandler: PlayerEventHandling {
    var onEvent: ((PlayerEvent.Kind, TimeInterval) -> Void)?
    var onProgress: ((TimeInterval) -> Void)?
    private(set) var attachCount = 0
    private(set) var invalidateCount = 0

    func attach(to player: AVPlayer) {
        attachCount += 1
    }

    func invalidate() {
        invalidateCount += 1
    }

    func send(_ kind: PlayerEvent.Kind, at position: TimeInterval = 0) {
        onEvent?(kind, position)
    }
}

struct StubError: LocalizedError {
    var errorDescription: String? { "Stub failure" }
}
