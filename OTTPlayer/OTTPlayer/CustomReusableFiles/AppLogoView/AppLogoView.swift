//
//  AppLogoView.swift
//  OTTPlayer
//
//  Created by Ayush on 28/10/26.
//

import UIKit

final class AppLogoView: UIView {

    private static let ringStartAngle: CGFloat = -15 * .pi / 180
    private static let ringEndAngle: CGFloat = 285 * .pi / 180

    private let ringGradientLayer = CAGradientLayer()
    private let ringLayer = CAShapeLayer()
    private let playLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = min(bounds.width, bounds.height)
        guard size > 0 else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let lineWidth = size * 0.071
        ringLayer.lineWidth = lineWidth
        ringLayer.path = UIBezierPath(arcCenter: center,
                                      radius: (size - lineWidth) / 2,
                                      startAngle: Self.ringStartAngle,
                                      endAngle: Self.ringEndAngle,
                                      clockwise: true).cgPath
        ringGradientLayer.frame = bounds
        ringLayer.frame = ringGradientLayer.bounds

        playLayer.frame = bounds
        playLayer.path = Self.playPath(center: CGPoint(x: center.x + size * 0.037, y: center.y),
                                       radius: size * 0.266,
                                       cornerRadius: size * 0.05)
        playLayer.shadowRadius = size * 0.04
        playLayer.shadowOffset = CGSize(width: 0, height: size * 0.015)
    }

    private func setupLayers() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        ringGradientLayer.colors = [UIColor.white.cgColor, UIColor(red: 0.56, green: 0.64, blue: 1, alpha: 1).cgColor]
        ringGradientLayer.startPoint = CGPoint(x: 0, y: 1)
        ringGradientLayer.endPoint = CGPoint(x: 1, y: 0)
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.strokeColor = UIColor.black.cgColor
        ringLayer.lineCap = .round
        ringGradientLayer.mask = ringLayer
        layer.addSublayer(ringGradientLayer)

        playLayer.fillColor = UIColor.white.cgColor
        playLayer.shadowColor = UIColor.black.cgColor
        playLayer.shadowOpacity = 0.35
        layer.addSublayer(playLayer)
    }

    private static func playPath(center: CGPoint, radius: CGFloat, cornerRadius: CGFloat) -> CGPath {
        let points = [0, 120, 240].map { degrees -> CGPoint in
            let angle = CGFloat(degrees) * .pi / 180
            return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        }
        let path = CGMutablePath()
        path.move(to: CGPoint(x: (points[2].x + points[0].x) / 2, y: (points[2].y + points[0].y) / 2))
        for index in points.indices {
            path.addArc(tangent1End: points[index], tangent2End: points[(index + 1) % points.count], radius: cornerRadius)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Animation
extension AppLogoView {

    func prepareForAnimation() {
        ringLayer.strokeEnd = 0
        playLayer.opacity = 0
    }

    func animateIn() {
        ringLayer.strokeEnd = 1
        let draw = CABasicAnimation(keyPath: "strokeEnd")
        draw.fromValue = 0
        draw.toValue = 1
        draw.duration = 0.8
        draw.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ringLayer.add(draw, forKey: "draw")

        playLayer.opacity = 1
        let pop = CASpringAnimation(keyPath: "transform.scale")
        pop.fromValue = 0.2
        pop.toValue = 1
        pop.damping = 11
        pop.initialVelocity = 4
        pop.duration = pop.settlingDuration
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0
        fade.toValue = 1
        fade.duration = 0.2
        let group = CAAnimationGroup()
        group.animations = [pop, fade]
        group.duration = pop.duration
        group.beginTime = CACurrentMediaTime() + 0.35
        group.fillMode = .backwards
        playLayer.add(group, forKey: "pop")
    }
}
