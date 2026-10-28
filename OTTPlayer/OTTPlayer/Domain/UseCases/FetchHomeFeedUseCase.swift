//
//  FetchHomeFeedUseCase.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

protocol FetchHomeFeedUseCase {
    func execute() async throws -> HomeFeed
}

final class DefaultFetchHomeFeedUseCase: FetchHomeFeedUseCase {

    private let repository: ContentRepository

    init(repository: ContentRepository) {
        self.repository = repository
    }

    func execute() async throws -> HomeFeed {
        try await repository.fetchHomeFeed()
    }
}
