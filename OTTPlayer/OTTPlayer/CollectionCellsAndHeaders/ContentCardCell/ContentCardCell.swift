//
//  ContentCardCell.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

final class ContentCardCell: UICollectionViewCell {

    static let textAreaHeight: CGFloat = 48

    // MARK: - IBOutlets
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var durationBadgeView: UIView!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.backgroundColor = Constants.Colors.surface
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.layer.cornerCurve = .continuous
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = Constants.Colors.cardBorder.cgColor
        thumbnailImageView.clipsToBounds = true

        durationBadgeView.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        durationBadgeView.layer.cornerRadius = 5
        durationBadgeView.layer.cornerCurve = .continuous
        durationLabel.textColor = Constants.Colors.primaryText
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)

        titleLabel.textColor = Constants.Colors.primaryText
        subtitleLabel.textColor = Constants.Colors.secondaryText

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.cancelImageLoad()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        durationLabel.text = nil
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
                self.alpha = self.isHighlighted ? 0.85 : 1
            }
        }
    }

    func configure(with content: ContentItem) {
        titleLabel.text = content.title
        subtitleLabel.text = content.shortMetadataText
        let timecode = content.duration?.timecodeText
        durationLabel.text = timecode
        durationBadgeView.isHidden = timecode == nil
        thumbnailImageView.setImage(from: content.thumbnailURL)

        accessibilityLabel = content.title
        accessibilityValue = content.metadataText
    }
}
