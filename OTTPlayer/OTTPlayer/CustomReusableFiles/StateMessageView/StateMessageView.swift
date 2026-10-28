//
//  StateMessageView.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

final class StateMessageView: UIView {

    enum StateType {
        case empty(message: String)
        case error(message: String)

        var iconName: String {
            switch self {
            case .empty: return "tv"
            case .error: return "exclamationmark.icloud"
            }
        }

        var title: String {
            switch self {
            case .empty: return "Nothing to watch yet"
            case .error: return "Something went wrong"
            }
        }

        var message: String {
            switch self {
            case .empty(let message), .error(let message): return message
            }
        }
    }

    private let retryAction: (() -> Void)?

    init(type: StateType, retryAction: (() -> Void)?) {
        self.retryAction = retryAction
        super.init(frame: .zero)
        setupView(type: type)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView(type: StateType) {
        let iconView = UIImageView(image: UIImage(systemName: type.iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 44, weight: .light)))
        iconView.tintColor = Constants.Colors.secondaryText
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = type.title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = Constants.Colors.primaryText
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = type.message
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textColor = Constants.Colors.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel, messageLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.setCustomSpacing(16, after: iconView)

        if retryAction != nil {
            var configuration = UIButton.Configuration.filled()
            configuration.title = "Try Again"
            configuration.baseBackgroundColor = Constants.Colors.accent
            configuration.cornerStyle = .capsule
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24)
            let retryButton = UIButton(configuration: configuration)
            retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
            stackView.addArrangedSubview(retryButton)
            stackView.setCustomSpacing(24, after: messageLabel)
        }

        addSubview(stackView)
        stackView.pinToEdges(of: self)
    }

    @objc private func retryTapped() {
        retryAction?()
    }
}
