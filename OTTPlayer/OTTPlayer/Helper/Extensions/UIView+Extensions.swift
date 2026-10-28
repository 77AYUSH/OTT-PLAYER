//
//  UIView+Extensions.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

private final class ScreenLoaderView: UIActivityIndicatorView {}

extension UIView {

    func pinToEdges(of container: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: container.leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topAnchor.constraint(equalTo: container.topAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    func showLoader() {
        guard !subviews.contains(where: { $0 is ScreenLoaderView }) else { return }
        let loader = ScreenLoaderView(style: .large)
        loader.color = Constants.Colors.primaryText
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.accessibilityLabel = "Loading"
        addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        loader.startAnimating()
    }

    func hideLoader() {
        subviews.filter { $0 is ScreenLoaderView }.forEach { $0.removeFromSuperview() }
    }
}
