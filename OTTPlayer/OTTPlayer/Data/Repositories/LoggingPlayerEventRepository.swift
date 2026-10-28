//
//  LoggingPlayerEventRepository.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

final class LoggingPlayerEventRepository: PlayerEventRepository {

    func record(_ event: PlayerEvent) {
        let position = String(format: "%.1f", event.position)
        AppLogger.analytics.info("\(event.name, privacy: .public) content=\(event.contentId, privacy: .public) position=\(position, privacy: .public)s\(Self.details(for: event.kind), privacy: .public)")
    }

    private static func details(for kind: PlayerEvent.Kind) -> String {
        switch kind {
        case .seeked(let from):
            return " from=\(String(format: "%.1f", from))s"
        case .failed(let message):
            return " error=\"\(message)\""
        default:
            return ""
        }
    }
}
