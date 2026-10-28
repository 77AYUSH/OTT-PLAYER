//
//  HomeViewModel.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation
import Combine

@MainActor
final class HomeViewModel {

    @Published private(set) var state: State = .idle

    private let fetchHomeFeedUseCase: FetchHomeFeedUseCase
    private var loadTask: Task<Void, Never>?
    private var activeRequestID: UUID?

    init(fetchHomeFeedUseCase: FetchHomeFeedUseCase) {
        self.fetchHomeFeedUseCase = fetchHomeFeedUseCase
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - Loading
extension HomeViewModel {

    func loadFeed() {
        loadTask?.cancel()
        let requestID = UUID()
        activeRequestID = requestID
        state = .loading

        let useCase = fetchHomeFeedUseCase
        loadTask = Task { [weak self] in
            do {
                let feed = try await useCase.execute()
                self?.handle(.success(feed), requestID: requestID)
            } catch {
                self?.handle(.failure(error), requestID: requestID)
            }
        }
    }

    private func handle(_ result: Result<HomeFeed, Error>, requestID: UUID) {
        guard requestID == activeRequestID else { return }
        activeRequestID = nil
        loadTask = nil

        switch result {
        case .success(let feed):
            state = feed.isEmpty ? .empty : .loaded(feed)
        case .failure(let error):
            if error is CancellationError { return }
            AppLogger.data.error("Home feed failed: \(String(describing: error), privacy: .public)")
            state = .error(message: error.userFacingMessage)
        }
    }
}

// MARK: - State
extension HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(HomeFeed)
        case empty
        case error(message: String)
    }
}
