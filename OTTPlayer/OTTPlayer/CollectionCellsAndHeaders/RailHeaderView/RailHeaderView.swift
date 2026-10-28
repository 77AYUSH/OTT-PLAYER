//
//  RailHeaderView.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

final class RailHeaderView: UICollectionReusableView {

    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = Constants.Colors.primaryText
        titleLabel.accessibilityTraits = .header
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
