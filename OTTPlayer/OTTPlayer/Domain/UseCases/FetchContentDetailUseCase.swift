//
//  FetchContentDetailUseCase.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

protocol FetchContentDetailUseCase {
    func execute(contentId: String) async throws -> ContentItem
}

final class DefaultFetchContentDetailUseCase: FetchContentDetailUseCase {

    private let repository: ContentRepository

    init(repository: ContentRepository) {
        self.repository = repository
    }

    func execute(contentId: String) async throws -> ContentItem {
        try await repository.fetchContent(id: contentId)
    }
}
