//
//  ContentDetailVC.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit
import Combine

final class ContentDetailVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var bannerImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var metadataLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!

    private let viewModel: ContentDetailViewModel
    private let screenFactory: ScreenFactory
    private var cancellables = Set<AnyCancellable>()
    private let transparentBarAppearance = NavHelper.transparentAppearance()
    private let solidBarAppearance = NavHelper.opaqueAppearance()
    private var isBarSolid: Bool?

    init(viewModel: ContentDetailViewModel, screenFactory: ScreenFactory) {
        self.viewModel = viewModel
        self.screenFactory = screenFactory
        super.init(nibName: "ContentDetailVC", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupBindings()
        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        updateNavigationBar(animated: false)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        scrollView.contentInset.bottom = view.safeAreaInsets.bottom + 16
        scrollView.verticalScrollIndicatorInsets.top = view.safeAreaInsets.top
    }

    @IBAction private func playButtonTapped(_ sender: UIButton) {
        guard let content = viewModel.content else { return }
        openPlayer(for: content)
    }
}

// MARK: - Setup
extension ContentDetailVC {

    private func setupView() {
        view.backgroundColor = Constants.Colors.background
        NavHelper.configureNavigationItem(for: self, title: "")
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        if #available(iOS 26.0, *) {
            // iOS 26 draws a blur band under the nav bar over the banner
            scrollView.topEdgeEffect.isHidden = true
        }

        bannerImageView.backgroundColor = Constants.Colors.surface
        titleLabel.textColor = Constants.Colors.primaryText
        metadataLabel.textColor = Constants.Colors.secondaryText
        descriptionLabel.textColor = Constants.Colors.primaryText.withAlphaComponent(0.78)

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Play"
        configuration.image = UIImage(systemName: "play.fill")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        configuration.imagePadding = 10
        configuration.baseBackgroundColor = .white
        configuration.baseForegroundColor = .black
        configuration.cornerStyle = .large
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 17, weight: .bold)
            return attributes
        }
        playButton.configuration = configuration
    }

    private func updateNavigationBar(animated: Bool) {
        // bounds not frame, the parallax transform changes the frame
        let threshold = headerView.bounds.height - view.safeAreaInsets.top - 24
        let shouldBeSolid = !scrollView.isHidden && headerView.bounds.height > 0 && scrollView.contentOffset.y > threshold
        guard shouldBeSolid != isBarSolid else { return }
        isBarSolid = shouldBeSolid

        let appearance = shouldBeSolid ? solidBarAppearance : transparentBarAppearance
        let apply = {
            self.navigationItem.standardAppearance = appearance
            self.navigationItem.scrollEdgeAppearance = appearance
            self.navigationItem.compactAppearance = appearance
        }
        if animated, let navigationBar = navigationController?.navigationBar {
            UIView.transition(with: navigationBar, duration: 0.2, options: .transitionCrossDissolve, animations: apply)
        } else {
            apply()
        }
    }
}

// MARK: - Bindings
extension ContentDetailVC {

    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: ContentDetailViewModel.State) {
        switch state {
        case .idle:
            break
        case .loading:
            hideStateView()
            scrollView.isHidden = true
            view.showLoader()
        case .loaded(let content):
            view.hideLoader()
            hideStateView()
            scrollView.isHidden = false
            show(content)
        case .error(let message):
            view.hideLoader()
            scrollView.isHidden = true
            showStateView(type: .error(message: message)) { [weak self] in
                self?.viewModel.load()
            }
        }
        updateNavigationBar(animated: false)
    }

    private func show(_ content: ContentItem) {
        navigationItem.title = content.title
        titleLabel.text = content.title
        metadataLabel.text = content.metadataText
        bannerImageView.setImage(from: content.bannerURL)
        playButton.accessibilityLabel = "Play \(content.title)"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.25
        descriptionLabel.attributedText = NSAttributedString(string: content.description, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: Constants.Colors.primaryText.withAlphaComponent(0.78)
        ])
    }
}

// MARK: - Scroll effects
extension ContentDetailVC: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let headerHeight = headerView.bounds.height
        if offsetY < 0, headerHeight > 0 {
            let scale = (headerHeight - offsetY) / headerHeight
            headerView.transform = CGAffineTransform(translationX: 0, y: offsetY / 2).scaledBy(x: scale, y: scale)
        } else {
            headerView.transform = CGAffineTransform(translationX: 0, y: offsetY * 0.35)
        }
        updateNavigationBar(animated: true)
    }
}

// MARK: - Navigation
extension ContentDetailVC {

    private func openPlayer(for content: ContentItem) {
        let playerVC = screenFactory.makePlayerVC(content: content)
        playerVC.modalPresentationStyle = .fullScreen
        present(playerVC, animated: true)
    }
}
