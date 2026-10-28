//
//  PlayerEvent.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

struct PlayerEvent: Equatable {

    enum Kind: Equatable {
        case ready
        case started
        case paused
        case resumed
        case seeked(from: TimeInterval)
        case bufferingStarted
        case bufferingEnded
        case completed
        case failed(message: String)
        case closed
    }

    let kind: Kind
    let contentId: String
    let position: TimeInterval
    let timestamp: Date

    init(kind: Kind, contentId: String, position: TimeInterval, timestamp: Date = Date()) {
        self.kind = kind
        self.contentId = contentId
        self.position = position
        self.timestamp = timestamp
    }

    var name: String {
        switch kind {
        case .ready: return "PLAYER_READY"
        case .started: return "PLAYER_STARTED"
        case .paused: return "PLAYER_PAUSED"
        case .resumed: return "PLAYER_RESUMED"
        case .seeked: return "PLAYER_SEEKED"
        case .bufferingStarted: return "PLAYER_BUFFERING_STARTED"
        case .bufferingEnded: return "PLAYER_BUFFERING_ENDED"
        case .completed: return "PLAYER_COMPLETED"
        case .failed: return "PLAYER_ERROR"
        case .closed: return "PLAYER_CLOSED"
        }
    }
}
