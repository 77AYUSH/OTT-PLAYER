//
//  PlayerEventHandler.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import AVFoundation
import Combine

@MainActor
protocol PlayerEventHandling: AnyObject {
    var onEvent: ((PlayerEvent.Kind, TimeInterval) -> Void)? { get set }
    var onProgress: ((TimeInterval) -> Void)? { get set }

    func attach(to player: AVPlayer)
    func invalidate()
}

@MainActor
final class PlayerEventHandler: PlayerEventHandling {

    var onEvent: ((PlayerEvent.Kind, TimeInterval) -> Void)?
    var onProgress: ((TimeInterval) -> Void)?

    private let seekThreshold: TimeInterval
    private let seekDebounce: TimeInterval

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()

    private var hasReportedReady = false
    private var hasStarted = false
    private var isPlaying = false
    private var isBuffering = false
    private var hasCompleted = false
    private var hasFailed = false

    private var lastPosition: TimeInterval = 0
    private var previousPosition: TimeInterval = 0
    private var pendingSeekOrigin: TimeInterval?
    private var pendingSeekTarget: TimeInterval = 0
    private var seekWorkItem: DispatchWorkItem?

    init(seekThreshold: TimeInterval = Constants.Player.seekThreshold,
         seekDebounce: TimeInterval = Constants.Player.seekDebounce) {
        self.seekThreshold = seekThreshold
        self.seekDebounce = seekDebounce
    }

    func attach(to player: AVPlayer) {
        invalidate()
        resetState()
        self.player = player
        guard let item = player.currentItem else { return }

        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] status in
                self?.processItemStatus(status, errorMessage: item?.error?.localizedDescription)
            }
            .store(in: &cancellables)

        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak player] status in
                self?.processTimeControlStatus(status, waitingReason: player?.reasonForWaitingToPlay)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.processPlaybackEnded()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                self?.processFailure(message: error?.localizedDescription ?? "Playback stopped unexpectedly.")
            }
            .store(in: &cancellables)

        // also fires when scrubbing with the native controls
        NotificationCenter.default.publisher(for: AVPlayerItem.timeJumpedNotification, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.processTimeJump(to: self.currentPosition)
            }
            .store(in: &cancellables)

        let interval = CMTime(seconds: Constants.Player.progressInterval, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                self?.processTick(position: time.seconds)
            }
        }
    }

    func invalidate() {
        cancellables.removeAll()
        seekWorkItem?.cancel()
        seekWorkItem = nil
        if let timeObserverToken {
            // has to be removed from the same player that added it
            player?.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil
        player = nil
    }

    private func resetState() {
        hasReportedReady = false
        hasStarted = false
        isPlaying = false
        isBuffering = false
        hasCompleted = false
        hasFailed = false
        lastPosition = 0
        previousPosition = 0
        pendingSeekOrigin = nil
        pendingSeekTarget = 0
    }

    private var currentPosition: TimeInterval {
        guard let seconds = player?.currentTime().seconds, seconds.isFinite else { return lastPosition }
        return seconds
    }

    private var isAtEndOfItem: Bool {
        guard let duration = player?.currentItem?.duration.seconds, duration.isFinite, duration > 0 else { return false }
        return currentPosition >= duration - Constants.Player.endOfItemTolerance
    }

    private func emit(_ kind: PlayerEvent.Kind, at position: TimeInterval? = nil) {
        onEvent?(kind, position ?? currentPosition)
    }
}

// MARK: - State processing
extension PlayerEventHandler {

    func processItemStatus(_ status: AVPlayerItem.Status, errorMessage: String?) {
        switch status {
        case .readyToPlay:
            guard !hasReportedReady, !hasFailed else { return }
            hasReportedReady = true
            emit(.ready)
        case .failed:
            processFailure(message: errorMessage ?? "This video can't be played right now.")
        default:
            break
        }
    }

    func processTimeControlStatus(_ status: AVPlayer.TimeControlStatus, waitingReason: AVPlayer.WaitingReason?, isAtEnd: Bool? = nil) {
        guard !hasFailed else { return }

        if status != .waitingToPlayAtSpecifiedRate, isBuffering {
            isBuffering = false
            emit(.bufferingEnded)
        }

        switch status {
        case .playing:
            if !hasStarted {
                hasStarted = true
                emit(.started)
            } else if !isPlaying {
                emit(.resumed)
            }
            isPlaying = true
            hasCompleted = false

        case .paused:
            // ignore the initial paused state and repeated pauses
            guard hasStarted, isPlaying else { return }
            isPlaying = false
            // AVPlayer also pauses at the end of the item, that's reported as completed
            guard !(isAtEnd ?? isAtEndOfItem), !hasCompleted else { return }
            emit(.paused)

        case .waitingToPlayAtSpecifiedRate:
            // skip the first load and the short buffering step after every seek/play
            guard hasStarted, !isBuffering, waitingReason == .toMinimizeStalls else { return }
            isBuffering = true
            emit(.bufferingStarted)

        @unknown default:
            break
        }
    }

    func processPlaybackEnded() {
        guard !hasCompleted, !hasFailed else { return }
        hasCompleted = true
        isPlaying = false
        emit(.completed)
    }

    func processFailure(message: String) {
        guard !hasFailed else { return }
        hasFailed = true
        isPlaying = false
        isBuffering = false
        emit(.failed(message: message))
    }

    func processTick(position: TimeInterval) {
        guard position.isFinite else { return }
        previousPosition = lastPosition
        lastPosition = position
        onProgress?(position)
    }

    // AVFoundation doesn't say where a jump came from, so use the last periodic tick.
    // The tick for the jump itself can arrive first, in that case use the one before it.
    func processTimeJump(to position: TimeInterval) {
        guard hasReportedReady, !hasFailed, position.isFinite else { return }

        if pendingSeekOrigin == nil {
            let tickAlreadyJumped = abs(position - lastPosition) < seekThreshold
                && abs(lastPosition - previousPosition) >= seekThreshold
            pendingSeekOrigin = tickAlreadyJumped ? previousPosition : lastPosition
        }
        pendingSeekTarget = position

        seekWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.finishSeek()
            }
        }
        seekWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + seekDebounce, execute: workItem)
    }

    private func finishSeek() {
        guard let origin = pendingSeekOrigin else { return }
        pendingSeekOrigin = nil
        seekWorkItem = nil

        let target = pendingSeekTarget
        guard abs(target - origin) >= seekThreshold else { return }

        if target < origin {
            hasCompleted = false
        }
        lastPosition = target
        previousPosition = target
        emit(.seeked(from: origin), at: target)
    }
}
