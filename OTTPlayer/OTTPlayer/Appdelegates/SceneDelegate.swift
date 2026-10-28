//
//  SceneDelegate.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let dependencies = AppDependencyContainer()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.tintColor = Constants.Colors.accent
        window.rootViewController = dependencies.makeRootViewController()
        window.makeKeyAndVisible()
        self.window = window
        showSplash(in: window)
    }

    // sits on top of home so the feed is already loading underneath
    private func showSplash(in window: UIWindow) {
        let splashView = SplashView(frame: window.bounds)
        splashView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(splashView)
        splashView.play()
    }
}
