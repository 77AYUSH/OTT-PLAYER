//
//  TrackPlayerEventUseCase.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

protocol TrackPlayerEventUseCase {
    func execute(_ event: PlayerEvent)
}

final class DefaultTrackPlayerEventUseCase: TrackPlayerEventUseCase {

    private let repository: PlayerEventRepository

    init(repository: PlayerEventRepository) {
        self.repository = repository
    }

    func execute(_ event: PlayerEvent) {
        repository.record(event)
    }
}
