//
//  NavHelper.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

enum NavHelper {

    static func applyAppAppearance(to navigationController: UINavigationController) {
        let appearance = opaqueAppearance()
        let navigationBar = navigationController.navigationBar
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = Constants.Colors.primaryText
    }

    static func opaqueAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
        appearance.backgroundColor = Constants.Colors.background.withAlphaComponent(0.6)
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: Constants.Colors.primaryText,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        return appearance
    }

    static func transparentAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.clear]
        return appearance
    }

    static func configureNavigationItem(for viewController: UIViewController, title: String) {
        viewController.navigationItem.title = title
        viewController.navigationItem.largeTitleDisplayMode = .never
        viewController.navigationItem.backButtonDisplayMode = .minimal
    }
}
