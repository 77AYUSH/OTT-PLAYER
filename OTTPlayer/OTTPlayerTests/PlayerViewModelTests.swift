//
//  PlayerViewModelTests.swift
//  OTTPlayerTests
//
//  Created by Ayush on 27/10/26.
//

import XCTest
@testable import OTTPlayer

@MainActor
final class PlayerViewModelTests: XCTestCase {

    private var handler: FakePlayerEventHandler!
    private var repository: SpyPlayerEventRepository!
    private var viewModel: PlayerViewModel!

    override func setUp() {
        super.setUp()
        handler = FakePlayerEventHandler()
        repository = SpyPlayerEventRepository()
        viewModel = PlayerViewModel(
            content: Fixtures.content(id: "movie-42"),
            eventHandler: handler,
            trackPlayerEventUseCase: DefaultTrackPlayerEventUseCase(repository: repository)
        )
    }

    func testEventsReachRepositoryWithContentIdAndPosition() {
        handler.send(.ready, at: 0)
        handler.send(.started, at: 0.2)
        handler.send(.paused, at: 12.5)
        handler.send(.seeked(from: 12.5), at: 90)

        XCTAssertEqual(repository.events.map(\.name), ["PLAYER_READY", "PLAYER_STARTED", "PLAYER_PAUSED", "PLAYER_SEEKED"])
        XCTAssertTrue(repository.events.allSatisfy { $0.contentId == "movie-42" })
        XCTAssertEqual(repository.events.map(\.position), [0, 0.2, 12.5, 90])
    }

    func testEventsDriveScreenState() {
        handler.send(.started)
        XCTAssertEqual(viewModel.state, .playing)

        handler.send(.bufferingStarted)
        XCTAssertEqual(viewModel.state, .buffering)

        handler.send(.bufferingEnded)
        XCTAssertEqual(viewModel.state, .playing)

        handler.send(.completed)
        XCTAssertEqual(viewModel.state, .completed)

        handler.send(.failed(message: "Offline"))
        XCTAssertEqual(viewModel.state, .failed(message: "Offline"))
        XCTAssertEqual(repository.events.last?.name, "PLAYER_ERROR")
    }

    func testStopRecordsCloseDetachesObserversAndIgnoresLateEvents() {
        handler.send(.started, at: 1)
        viewModel.stop()
        handler.send(.paused, at: 5)
        viewModel.stop()

        XCTAssertEqual(repository.events.map(\.name), ["PLAYER_STARTED", "PLAYER_CLOSED"])
        XCTAssertEqual(handler.invalidateCount, 1)
        XCTAssertNil(viewModel.player)
    }

    func testViewModelIsReleasedAfterStop() {
        weak var weakViewModel: PlayerViewModel?
        weakViewModel = viewModel
        viewModel.stop()
        viewModel = nil

        XCTAssertNil(weakViewModel, "the handler's callbacks must not retain the view model")
    }
}
