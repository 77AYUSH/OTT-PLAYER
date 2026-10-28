//
//  CarouselCardCell.swift
//  OTTPlayer
//
//  Created by Ayush on 28/10/26.
//

import UIKit

final class CarouselCardCell: UICollectionViewCell {

    // MARK: - IBOutlets
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var metadataLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 16
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Constants.Colors.cardBorder.cgColor
        cardView.clipsToBounds = true
        artworkImageView.backgroundColor = Constants.Colors.surface
        titleLabel.textColor = Constants.Colors.primaryText
        metadataLabel.textColor = Constants.Colors.secondaryText

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 10)

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 16).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artworkImageView.cancelImageLoad()
        artworkImageView.image = nil
    }

    func configure(with content: ContentItem) {
        titleLabel.text = content.title
        metadataLabel.text = content.metadataText
        artworkImageView.setImage(from: content.bannerURL)
        accessibilityLabel = content.title
        accessibilityValue = content.metadataText
    }
}
