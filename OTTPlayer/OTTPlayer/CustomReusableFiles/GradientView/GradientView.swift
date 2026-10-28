//
//  GradientView.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

final class GradientView: UIView {

    @IBInspectable var fadesFromTop: Bool = false {
        didSet { configureGradient() }
    }

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureGradient()
    }

    private func configureGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        let base = Constants.Colors.background
        if fadesFromTop {
            // eased curve, a linear fade shows a visible edge
            let stops: [CGFloat] = [0, 0.2, 0.4, 0.6, 0.8, 1]
            gradientLayer.colors = stops.map { base.withAlphaComponent(0.7 * pow(1 - $0, 2)).cgColor }
            gradientLayer.locations = stops.map { NSNumber(value: Double($0)) }
        } else {
            gradientLayer.colors = [
                base.withAlphaComponent(0).cgColor,
                base.withAlphaComponent(0.15).cgColor,
                base.withAlphaComponent(0.7).cgColor,
                base.cgColor
            ]
            gradientLayer.locations = [0, 0.45, 0.8, 1]
        }
        isUserInteractionEnabled = false
    }
}
