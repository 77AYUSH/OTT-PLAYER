//
//  ContentDetailViewModel.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation
import Combine

@MainActor
final class ContentDetailViewModel {

    @Published private(set) var state: State = .idle

    let contentId: String
    private let fetchContentDetailUseCase: FetchContentDetailUseCase
    private var loadTask: Task<Void, Never>?

    init(contentId: String, fetchContentDetailUseCase: FetchContentDetailUseCase) {
        self.contentId = contentId
        self.fetchContentDetailUseCase = fetchContentDetailUseCase
    }

    deinit {
        loadTask?.cancel()
    }

    var content: ContentItem? {
        if case .loaded(let content) = state {
            return content
        }
        return nil
    }
}

// MARK: - Loading
extension ContentDetailViewModel {

    func load() {
        loadTask?.cancel()
        state = .loading

        let useCase = fetchContentDetailUseCase
        let contentId = contentId
        loadTask = Task { [weak self] in
            do {
                let content = try await useCase.execute(contentId: contentId)
                guard !Task.isCancelled else { return }
                self?.state = .loaded(content)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .error(message: error.userFacingMessage)
            }
        }
    }
}

// MARK: - State
extension ContentDetailViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(ContentItem)
        case error(message: String)
    }
}
