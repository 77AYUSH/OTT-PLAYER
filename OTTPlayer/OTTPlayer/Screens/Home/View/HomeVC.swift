//
//  HomeVC.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit
import Combine

final class HomeVC: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var statusBarBackdropView: UIVisualEffectView!

    private let viewModel: HomeViewModel
    private let screenFactory: ScreenFactory
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    init(viewModel: HomeViewModel, screenFactory: ScreenFactory) {
        self.viewModel = viewModel
        self.screenFactory = screenFactory
        super.init(nibName: "HomeVC", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setUpCollectionView()
        setupBindings()
        viewModel.loadFeed()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visibleCarouselCells.forEach { $0.startAutoScroll() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        visibleCarouselCells.forEach { $0.stopAutoScroll() }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        collectionView.contentInset.bottom = view.safeAreaInsets.bottom + 16
        collectionView.verticalScrollIndicatorInsets.top = view.safeAreaInsets.top
        updateStatusBarBackdrop()
    }
}

// MARK: - Setup
extension HomeVC {

    private func setupView() {
        view.backgroundColor = Constants.Colors.background
        NavHelper.configureNavigationItem(for: self, title: "Home")
        statusBarBackdropView.alpha = 0
    }

    private func setUpCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.collectionViewLayout = makeLayout()
        collectionView.delegate = self
        collectionView.register(cell: HeroBannerCell.self)
        collectionView.register(cell: ContentCardCell.self)
        collectionView.register(cell: FeaturedCarouselCell.self)
        collectionView.registerHeader(header: RailHeaderView.self)
        dataSource = configureDataSource()
    }

    private var visibleCarouselCells: [FeaturedCarouselCell] {
        collectionView.visibleCells.compactMap { $0 as? FeaturedCarouselCell }
    }

    private func updateStatusBarBackdrop() {
        guard let heroFrame = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0))?.frame,
              case .hero = dataSource.sectionIdentifier(for: 0) else {
            statusBarBackdropView.alpha = 1
            return
        }
        // fade in before the hero text reaches the status bar
        let fadeStart = heroFrame.maxY - view.safeAreaInsets.top - 320
        let progress = (collectionView.contentOffset.y - fadeStart) / 80
        statusBarBackdropView.alpha = min(max(progress, 0), 1)
    }
}

// MARK: - Bindings
extension HomeVC {

    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: HomeViewModel.State) {
        switch state {
        case .idle:
            break
        case .loading:
            hideStateView()
            collectionView.isHidden = true
            view.showLoader()
        case .loaded(let feed):
            view.hideLoader()
            hideStateView()
            collectionView.isHidden = false
            applySnapshot(for: feed)
        case .empty:
            view.hideLoader()
            collectionView.isHidden = true
            showStateView(type: .empty(message: "New titles will show up here soon.")) { [weak self] in
                self?.viewModel.loadFeed()
            }
        case .error(let message):
            view.hideLoader()
            collectionView.isHidden = true
            showStateView(type: .error(message: message)) { [weak self] in
                self?.viewModel.loadFeed()
            }
        }
        updateStatusBarBackdrop()
    }
}

// MARK: - Data source
extension HomeVC {

    enum Section: Hashable {
        case hero
        case rail(id: String, title: String)
        case carousel(id: String, title: String)
    }

    enum Item: Hashable {
        case hero(HomeHero)
        // same title can show up in more than one rail
        case content(railId: String, ContentItem)
        case carousel(ContentRail)
    }

    private func configureDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            switch item {
            case .hero(let hero):
                let cell: HeroBannerCell = collectionView.dequeue(for: indexPath)
                cell.configure(with: hero)
                cell.onPlayTapped = { [weak self] in
                    self?.openPlayer(for: hero.content)
                }
                cell.onDetailsTapped = { [weak self] in
                    self?.openContentDetail(contentId: hero.content.id)
                }
                return cell
            case .content(_, let content):
                let cell: ContentCardCell = collectionView.dequeue(for: indexPath)
                cell.configure(with: content)
                return cell
            case .carousel(let rail):
                let cell: FeaturedCarouselCell = collectionView.dequeue(for: indexPath)
                cell.configure(with: rail.items)
                cell.onSelect = { [weak self] content in
                    self?.openContentDetail(contentId: content.id)
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, _, indexPath in
            let header: RailHeaderView = collectionView.dequeueHeader(for: indexPath)
            switch self?.dataSource.sectionIdentifier(for: indexPath.section) {
            case .rail(_, let title), .carousel(_, let title):
                header.configure(title: title)
            default:
                break
            }
            return header
        }
        return dataSource
    }

    private func applySnapshot(for feed: HomeFeed) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        if let hero = feed.hero {
            snapshot.appendSections([.hero])
            snapshot.appendItems([.hero(hero)], toSection: .hero)
        }
        for rail in feed.rails {
            switch rail.style {
            case .standard:
                let section = Section.rail(id: rail.id, title: rail.title)
                snapshot.appendSections([section])
                snapshot.appendItems(rail.items.map { .content(railId: rail.id, $0) }, toSection: section)
            case .carousel:
                let section = Section.carousel(id: rail.id, title: rail.title)
                snapshot.appendSections([section])
                snapshot.appendItems([.carousel(rail)], toSection: section)
            }
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Layout
extension HomeVC {

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            switch self?.dataSource.sectionIdentifier(for: sectionIndex) {
            case .hero:
                return Self.heroSection(environment: environment)
            case .carousel:
                return Self.carouselSection(environment: environment)
            default:
                return Self.railSection(environment: environment)
            }
        }
    }

    private static func heroSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let width = environment.container.effectiveContentSize.width
        let height = min(max(width * 1.35, 460), 600)
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0)
        return section
    }

    private static func railSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.effectiveContentSize.width
        let cardWidth = min(max((containerWidth - 16 - 12) / 2.3, 150), 260).rounded()
        let cardHeight = (cardWidth * 9 / 16).rounded() + ContentCardCell.textAreaHeight

        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(cardWidth), heightDimension: .absolute(cardHeight)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 28, trailing: 16)
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    private static func carouselSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let width = environment.container.effectiveContentSize.width
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(FeaturedCarouselCell.height(forWidth: width))),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
        let header = makeHeader()
        header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        section.boundarySupplementaryItems = [header]
        return section
    }

    private static func makeHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(30)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
}

// MARK: - Collection view delegate
extension HomeVC: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath) {
        case .hero(let hero):
            openContentDetail(contentId: hero.content.id)
        case .content(_, let content):
            openContentDetail(contentId: content.id)
        case .carousel, .none:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let carouselCell = cell as? FeaturedCarouselCell, viewIfLoaded?.window != nil else { return }
        carouselCell.startAutoScroll()
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? FeaturedCarouselCell)?.stopAutoScroll()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateStatusBarBackdrop()
    }
}

// MARK: - Navigation
extension HomeVC {

    private func openContentDetail(contentId: String) {
        let detailVC = screenFactory.makeContentDetailVC(contentId: contentId)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func openPlayer(for content: ContentItem) {
        let playerVC = screenFactory.makePlayerVC(content: content)
        playerVC.modalPresentationStyle = .fullScreen
        present(playerVC, animated: true)
    }
}
