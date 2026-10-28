//
//  HeroBannerCell.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

final class HeroBannerCell: UICollectionViewCell {

    // MARK: - IBOutlets
    @IBOutlet private weak var bannerImageView: UIImageView!
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var eyebrowLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var metadataLabel: UILabel!
    @IBOutlet private weak var taglineLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var detailsButton: UIButton!

    var onPlayTapped: (() -> Void)?
    var onDetailsTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        bannerImageView.backgroundColor = Constants.Colors.surface

        eyebrowLabel.attributedText = NSAttributedString(string: "FEATURED", attributes: [
            .kern: 2.0,
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: Constants.Colors.primaryText.withAlphaComponent(0.9)
        ])
        titleLabel.textColor = Constants.Colors.primaryText
        metadataLabel.textColor = Constants.Colors.secondaryText
        taglineLabel.textColor = Constants.Colors.primaryText.withAlphaComponent(0.85)
        [eyebrowLabel, titleLabel, metadataLabel, taglineLabel].forEach { label in
            label?.layer.shadowColor = UIColor.black.cgColor
            label?.layer.shadowOpacity = 0.55
            label?.layer.shadowRadius = 8
            label?.layer.shadowOffset = .zero
        }
        contentStackView.setCustomSpacing(4, after: eyebrowLabel)
        contentStackView.setCustomSpacing(20, after: taglineLabel)

        playButton.configuration = Self.buttonConfiguration(title: "Play", systemImage: "play.fill", isPrimary: true)
        detailsButton.configuration = Self.buttonConfiguration(title: "Details", systemImage: "info.circle", isPrimary: false)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bannerImageView.cancelImageLoad()
        bannerImageView.image = nil
        onPlayTapped = nil
        onDetailsTapped = nil
    }

    func configure(with hero: HomeHero) {
        titleLabel.text = hero.content.title
        metadataLabel.text = hero.content.metadataText
        taglineLabel.text = hero.tagline
        bannerImageView.setImage(from: hero.content.bannerURL)
        playButton.accessibilityLabel = "Play \(hero.content.title)"
        detailsButton.accessibilityLabel = "Details for \(hero.content.title)"
    }

    @IBAction private func playButtonTapped(_ sender: UIButton) {
        onPlayTapped?()
    }

    @IBAction private func detailsButtonTapped(_ sender: UIButton) {
        onDetailsTapped?()
    }

    private static func buttonConfiguration(title: String, systemImage: String, isPrimary: Bool) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: systemImage)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        configuration.imagePadding = 8
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 16, weight: .bold)
            return attributes
        }
        if isPrimary {
            configuration.baseBackgroundColor = .white
            configuration.baseForegroundColor = .black
        } else {
            configuration.baseForegroundColor = .white
            configuration.background.backgroundColor = UIColor.white.withAlphaComponent(0.12)
            configuration.background.visualEffect = UIBlurEffect(style: .systemThinMaterialDark)
        }
        return configuration
    }
}
