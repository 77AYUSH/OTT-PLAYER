//
//  PlayerEventHandlerTests.swift
//  OTTPlayerTests
//
//  Created by Ayush on 27/10/26.
//

import XCTest
import AVFoundation
@testable import OTTPlayer

@MainActor
final class PlayerEventHandlerTests: XCTestCase {

    private var handler: PlayerEventHandler!
    private var events: [PlayerEvent.Kind] = []

    override func setUp() {
        super.setUp()
        handler = PlayerEventHandler(seekThreshold: 1.0, seekDebounce: 0.05)
        events = []
        handler.onEvent = { [unowned self] kind, _ in events.append(kind) }
    }

    func testReadyAndStartAreReportedOnce() {
        handler.processItemStatus(.readyToPlay, errorMessage: nil)
        handler.processItemStatus(.readyToPlay, errorMessage: nil)
        handler.processTimeControlStatus(.paused, waitingReason: nil)          // initial state, not a user pause
        handler.processTimeControlStatus(.waitingToPlayAtSpecifiedRate, waitingReason: .evaluatingBufferingRate)
        handler.processTimeControlStatus(.playing, waitingReason: nil)
        handler.processTimeControlStatus(.playing, waitingReason: nil)

        XCTAssertEqual(events, [.ready, .started], "initial load is not reported as buffering")
    }

    func testPauseAndResumeAreDistinguishedFromStart() {
        play()
        handler.processTimeControlStatus(.paused, waitingReason: nil, isAtEnd: false)
        handler.processTimeControlStatus(.paused, waitingReason: nil, isAtEnd: false)
        handler.processTimeControlStatus(.playing, waitingReason: nil)

        XCTAssertEqual(events, [.ready, .started, .paused, .resumed])
    }

    func testStallProducesSingleBufferingPair() {
        play()
        handler.processTimeControlStatus(.waitingToPlayAtSpecifiedRate, waitingReason: .evaluatingBufferingRate)
        handler.processTimeControlStatus(.playing, waitingReason: nil)
        handler.processTimeControlStatus(.waitingToPlayAtSpecifiedRate, waitingReason: .toMinimizeStalls)
        handler.processTimeControlStatus(.waitingToPlayAtSpecifiedRate, waitingReason: .toMinimizeStalls)
        handler.processTimeControlStatus(.playing, waitingReason: nil)

        XCTAssertEqual(events, [.ready, .started, .bufferingStarted, .bufferingEnded],
                       "buffering recovery is not reported as a resume")
    }

    func testPauseAtEndOfItemIsReportedAsCompletionOnly() {
        play()
        handler.processTimeControlStatus(.paused, waitingReason: nil, isAtEnd: true)
        handler.processPlaybackEnded()
        handler.processPlaybackEnded()

        XCTAssertEqual(events, [.ready, .started, .completed])
    }

    func testFailureIsReportedOnceAndSilencesLaterSignals() {
        play()
        handler.processFailure(message: "Network lost")
        handler.processItemStatus(.failed, errorMessage: "Network lost")
        handler.processTimeControlStatus(.paused, waitingReason: nil, isAtEnd: false)

        XCTAssertEqual(events, [.ready, .started, .failed(message: "Network lost")])
    }

    func testScrubBurstIsCoalescedIntoOneSeek() async throws {
        play()
        handler.processTick(position: 10)
        handler.processTick(position: 10.5)
        handler.processTimeJump(to: 30)
        handler.processTimeJump(to: 45)
        handler.processTimeJump(to: 60)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(events, [.ready, .started, .seeked(from: 10.5)])
    }

    func testSeekOriginIsCorrectWhenTickArrivesBeforeNotification() async throws {
        play()
        handler.processTick(position: 19.5)
        handler.processTick(position: 20)
        handler.processTick(position: 5)    // periodic observer already saw the jump
        handler.processTimeJump(to: 5)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(events.last, .seeked(from: 20))
    }

    func testTinyJumpsAreIgnored() async throws {
        play()
        handler.processTick(position: 9.5)
        handler.processTick(position: 10)
        handler.processTimeJump(to: 10.4)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(events, [.ready, .started])
    }

    private func play() {
        handler.processItemStatus(.readyToPlay, errorMessage: nil)
        handler.processTimeControlStatus(.playing, waitingReason: nil)
    }
}
