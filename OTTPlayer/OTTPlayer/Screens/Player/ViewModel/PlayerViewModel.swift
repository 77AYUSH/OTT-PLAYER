//
//  PlayerViewModel.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import AVFoundation
import Combine
import UIKit

@MainActor
final class PlayerViewModel {

    @Published private(set) var state: State = .loading

    let content: ContentItem
    private(set) var player: AVPlayer?

    private let eventHandler: PlayerEventHandling
    private let trackPlayerEventUseCase: TrackPlayerEventUseCase
    private let notificationCenter: NotificationCenter
    private var lifecycleCancellables = Set<AnyCancellable>()
    private var lastKnownPosition: TimeInterval = 0
    private var resumePosition: TimeInterval?
    private var isStopped = false

    init(content: ContentItem,
         eventHandler: PlayerEventHandling,
         trackPlayerEventUseCase: TrackPlayerEventUseCase,
         notificationCenter: NotificationCenter = .default) {
        self.content = content
        self.eventHandler = eventHandler
        self.trackPlayerEventUseCase = trackPlayerEventUseCase
        self.notificationCenter = notificationCenter

        eventHandler.onEvent = { [weak self] kind, position in
            self?.handle(kind, at: position)
        }
        eventHandler.onProgress = { [weak self] position in
            self?.lastKnownPosition = position
        }
    }

    var title: String {
        content.title
    }
}

// MARK: - Playback control
extension PlayerViewModel {

    func startPlayback() -> AVPlayer {
        if let player {
            return player
        }
        let player = AVPlayer(playerItem: AVPlayerItem(url: content.videoURL))
        self.player = player
        eventHandler.attach(to: player)
        observeAppLifecycle()
        state = .loading
        player.play()
        return player
    }

    func retry() {
        guard case .failed = state, let player, !isStopped else { return }
        resumePosition = lastKnownPosition > 0 ? lastKnownPosition : nil

        eventHandler.invalidate()
        player.replaceCurrentItem(with: AVPlayerItem(url: content.videoURL))
        eventHandler.attach(to: player)
        state = .loading
        player.play()
    }

    // remove observers before pausing, otherwise closing logs a PLAYER_PAUSED
    func stop() {
        guard !isStopped else { return }
        let closingPosition = currentPosition
        record(.closed, at: closingPosition)
        isStopped = true

        eventHandler.invalidate()
        lifecycleCancellables.removeAll()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }

    private var currentPosition: TimeInterval {
        guard let seconds = player?.currentTime().seconds, seconds.isFinite else { return lastKnownPosition }
        return seconds
    }
}

// MARK: - Event handling
extension PlayerViewModel {

    func handle(_ kind: PlayerEvent.Kind, at position: TimeInterval) {
        guard !isStopped else { return }
        lastKnownPosition = position
        record(kind, at: position)

        switch kind {
        case .ready:
            seekToResumePositionIfNeeded()
        case .started, .resumed, .bufferingEnded:
            state = .playing
        case .paused:
            state = .paused
        case .bufferingStarted:
            state = .buffering
        case .completed:
            state = .completed
        case .failed(let message):
            state = .failed(message: message)
        case .seeked, .closed:
            break
        }
    }

    private func record(_ kind: PlayerEvent.Kind, at position: TimeInterval) {
        trackPlayerEventUseCase.execute(PlayerEvent(kind: kind, contentId: content.id, position: position))
    }

    private func seekToResumePositionIfNeeded() {
        guard let resumePosition, let player else { return }
        self.resumePosition = nil
        player.seek(to: CMTime(seconds: resumePosition, preferredTimescale: 600))
    }
}

// MARK: - App lifecycle
extension PlayerViewModel {

    // no background playback mode enabled, so pause explicitly
    private func observeAppLifecycle() {
        lifecycleCancellables.removeAll()
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.player?.pause()
            }
            .store(in: &lifecycleCancellables)
    }
}

// MARK: - State
extension PlayerViewModel {
    enum State: Equatable {
        case loading
        case buffering
        case playing
        case paused
        case completed
        case failed(message: String)
    }
}
