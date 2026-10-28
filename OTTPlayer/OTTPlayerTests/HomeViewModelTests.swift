//
//  HomeViewModelTests.swift
//  OTTPlayerTests
//
//  Created by Ayush on 27/10/26.
//

import XCTest
import Combine
@testable import OTTPlayer

@MainActor
final class HomeViewModelTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testSuccessfulLoadGoesThroughLoadingToLoaded() async {
        let feed = Fixtures.feed()
        let viewModel = HomeViewModel(fetchHomeFeedUseCase: StubFetchHomeFeedUseCase(responses: [.init(result: .success(feed), delay: 0)]))
        let states = record(viewModel)

        viewModel.loadFeed()
        await waitForState(of: viewModel) { $0 == .loaded(feed) }

        XCTAssertEqual(states.values, [.idle, .loading, .loaded(feed)])
    }

    func testEmptyFeedProducesEmptyState() async {
        let emptyFeed = HomeFeed(hero: nil, rails: [])
        let viewModel = HomeViewModel(fetchHomeFeedUseCase: StubFetchHomeFeedUseCase(responses: [.init(result: .success(emptyFeed), delay: 0)]))

        viewModel.loadFeed()
        await waitForState(of: viewModel) { $0 == .empty }
    }

    func testFailureProducesErrorAndRetryRecovers() async {
        let feed = Fixtures.feed()
        let useCase = StubFetchHomeFeedUseCase(responses: [
            .init(result: .failure(StubError()), delay: 0),
            .init(result: .success(feed), delay: 0)
        ])
        let viewModel = HomeViewModel(fetchHomeFeedUseCase: useCase)

        viewModel.loadFeed()
        await waitForState(of: viewModel) { $0 == .error(message: "Stub failure") }

        viewModel.loadFeed()
        await waitForState(of: viewModel) { $0 == .loaded(feed) }
        XCTAssertEqual(useCase.callCount, 2)
    }

    func testStaleResultIsDiscarded() async throws {
        let staleFeed = Fixtures.feed(railCount: 1)
        let freshFeed = Fixtures.feed(railCount: 3)
        let useCase = StubFetchHomeFeedUseCase(responses: [
            .init(result: .success(staleFeed), delay: 0.3),
            .init(result: .success(freshFeed), delay: 0.05)
        ])
        let viewModel = HomeViewModel(fetchHomeFeedUseCase: useCase)
        let states = record(viewModel)

        viewModel.loadFeed()
        // wait until the slow request is in flight
        while useCase.callCount < 1 {
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        viewModel.loadFeed()
        await waitForState(of: viewModel) { $0 == .loaded(freshFeed) }
        // let the stale request finish
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(viewModel.state, .loaded(freshFeed))
        XCTAssertFalse(states.values.contains(.loaded(staleFeed)))
    }

    // MARK: - Helpers

    private final class StateRecorder {
        var values: [HomeViewModel.State] = []
    }

    private func record(_ viewModel: HomeViewModel) -> StateRecorder {
        let recorder = StateRecorder()
        viewModel.$state.sink { recorder.values.append($0) }.store(in: &cancellables)
        return recorder
    }

    private func waitForState(of viewModel: HomeViewModel, timeout: TimeInterval = 2, file: StaticString = #filePath, line: UInt = #line, _ predicate: @escaping (HomeViewModel.State) -> Bool) async {
        let expectation = expectation(description: "state reached")
        expectation.assertForOverFulfill = false
        viewModel.$state.sink { state in
            if predicate(state) { expectation.fulfill() }
        }
        .store(in: &cancellables)
        await fulfillment(of: [expectation], timeout: timeout)
    }
}
