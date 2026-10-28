//
//  SplashView.swift
//  OTTPlayer
//
//  Created by Ayush on 28/10/26.
//

import UIKit

final class SplashView: UIView {

    private let glowView = RadialGlowView()
    private let logoView = AppLogoView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play(completion: (() -> Void)? = nil) {
        if UIAccessibility.isReduceMotionEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.dismiss(zoom: false, completion: completion)
            }
            return
        }

        logoView.prepareForAnimation()
        glowView.alpha = 0
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 14)

        logoView.animateIn()
        UIView.animate(withDuration: 0.9, delay: 0.1, options: .curveEaseOut) {
            self.glowView.alpha = 1
        }
        UIView.animate(withDuration: 0.5, delay: 0.6, options: .curveEaseOut) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            self.dismiss(zoom: true, completion: completion)
        }
    }

    private func dismiss(zoom: Bool, completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.45, delay: 0, options: .curveEaseIn) {
            if zoom {
                self.logoView.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                self.titleLabel.transform = CGAffineTransform(translationX: 0, y: 10)
            }
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}

// MARK: - Setup
extension SplashView {

    private func setupView() {
        backgroundColor = Constants.Colors.background
        accessibilityViewIsModal = true

        titleLabel.text = "OTT Player"
        titleLabel.textColor = Constants.Colors.primaryText
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        [glowView, logoView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            logoView.widthAnchor.constraint(equalToConstant: 120),
            logoView.heightAnchor.constraint(equalTo: logoView.widthAnchor),

            glowView.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            glowView.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
            glowView.widthAnchor.constraint(equalToConstant: 440),
            glowView.heightAnchor.constraint(equalTo: glowView.widthAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 28)
        ])
    }
}

private final class RadialGlowView: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.type = .radial
        gradientLayer.colors = [Constants.Colors.accent.withAlphaComponent(0.35).cgColor,
                                Constants.Colors.accent.withAlphaComponent(0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
