//
//  PlayerVC.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit
import AVKit
import Combine

final class PlayerVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var errorContainerView: UIView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var retryButton: UIButton!

    private let viewModel: PlayerViewModel
    private let playerViewController = AVPlayerViewController()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "PlayerVC", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        embedPlayerViewController()
        setupBindings()
        playerViewController.player = viewModel.startPlayback()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // AVKit fullscreen triggers this too, only clean up on a real dismiss
        guard isBeingDismissed else { return }
        playerViewController.player = nil
        viewModel.stop()
    }

    @IBAction private func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction private func retryButtonTapped(_ sender: UIButton) {
        viewModel.retry()
    }
}

// MARK: - Setup
extension PlayerVC {

    private func setupView() {
        view.backgroundColor = .black
        titleLabel.text = viewModel.title
        titleLabel.textColor = Constants.Colors.primaryText
        closeButton.tintColor = Constants.Colors.primaryText
        closeButton.accessibilityLabel = "Close player"

        errorContainerView.isHidden = true
        errorLabel.textColor = Constants.Colors.primaryText

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Try Again"
        configuration.baseBackgroundColor = Constants.Colors.accent
        configuration.cornerStyle = .capsule
        retryButton.configuration = configuration
    }

    private func embedPlayerViewController() {
        playerViewController.allowsPictureInPicturePlayback = false
        playerViewController.videoGravity = .resizeAspect
        addChild(playerViewController)
        playerContainerView.addSubview(playerViewController.view)
        playerViewController.view.pinToEdges(of: playerContainerView)
        playerViewController.didMove(toParent: self)
    }
}

// MARK: - Bindings
extension PlayerVC {

    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: PlayerViewModel.State) {
        let hasFailed: Bool
        switch state {
        case .loading, .buffering:
            hasFailed = false
            loadingIndicator.startAnimating()
        case .playing, .paused, .completed:
            hasFailed = false
            loadingIndicator.stopAnimating()
        case .failed(let message):
            hasFailed = true
            loadingIndicator.stopAnimating()
            errorLabel.text = message
        }
        // hide AVKit's own error glyph behind our message
        playerViewController.view.isHidden = hasFailed
        errorContainerView.isHidden = !hasFailed
    }
}
