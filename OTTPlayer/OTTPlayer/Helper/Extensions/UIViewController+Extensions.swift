//
//  UIViewController+Extensions.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

extension UIViewController {

    func showStateView(type: StateMessageView.StateType, retryAction: (() -> Void)?) {
        hideStateView()
        let stateView = StateMessageView(type: type, retryAction: retryAction)
        view.addSubview(stateView)
        stateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            stateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            stateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }

    func hideStateView() {
        view.subviews.filter { $0 is StateMessageView }.forEach { $0.removeFromSuperview() }
    }
}
