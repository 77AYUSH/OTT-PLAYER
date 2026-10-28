//
//  AppDependencyContainer.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

@MainActor
protocol ScreenFactory: AnyObject {
    func makeContentDetailVC(contentId: String) -> UIViewController
    func makePlayerVC(content: ContentItem) -> UIViewController
}

@MainActor
final class AppDependencyContainer {

    private lazy var contentRepository: ContentRepository = DefaultContentRepository(
        dataSource: StaticHomeFeedDataSource(
            fileName: Constants.homeFeedFileName,
            simulatedLatency: Constants.simulatedFeedLatency
        )
    )

    private lazy var playerEventRepository: PlayerEventRepository = LoggingPlayerEventRepository()

    func makeRootViewController() -> UIViewController {
        let navigationController = UINavigationController(rootViewController: makeHomeVC())
        NavHelper.applyAppAppearance(to: navigationController)
        return navigationController
    }

    func makeHomeVC() -> HomeVC {
        let useCase = DefaultFetchHomeFeedUseCase(repository: contentRepository)
        return HomeVC(viewModel: HomeViewModel(fetchHomeFeedUseCase: useCase), screenFactory: self)
    }
}

// MARK: - Screen factory
extension AppDependencyContainer: ScreenFactory {

    func makeContentDetailVC(contentId: String) -> UIViewController {
        let useCase = DefaultFetchContentDetailUseCase(repository: contentRepository)
        let viewModel = ContentDetailViewModel(contentId: contentId, fetchContentDetailUseCase: useCase)
        return ContentDetailVC(viewModel: viewModel, screenFactory: self)
    }

    func makePlayerVC(content: ContentItem) -> UIViewController {
        let viewModel = PlayerViewModel(
            content: content,
            eventHandler: PlayerEventHandler(),
            trackPlayerEventUseCase: DefaultTrackPlayerEventUseCase(repository: playerEventRepository)
        )
        return PlayerVC(viewModel: viewModel)
    }
}
