//
//  CarouselFlowLayout.swift
//  OTTPlayer
//
//  Created by Ayush on 28/10/26.
//

import UIKit

final class CarouselFlowLayout: UICollectionViewFlowLayout {

    private let sideScale: CGFloat = 0.86
    private let sideAlpha: CGFloat = 0.5
    private let cardSpacing: CGFloat = 12

    static func itemSize(forContainerWidth width: CGFloat) -> CGSize {
        let itemWidth = min(width * 0.74, 440).rounded()
        return CGSize(width: itemWidth, height: (itemWidth * 9 / 16).rounded())
    }

    override init() {
        super.init()
        scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        scrollDirection = .horizontal
    }

    var pageWidth: CGFloat {
        itemSize.width + minimumLineSpacing
    }

    override func prepare() {
        if let collectionView {
            let bounds = collectionView.bounds
            let size = Self.itemSize(forContainerWidth: bounds.width)
            let spacing = cardSpacing
            let horizontalInset = ((bounds.width - size.width) / 2).rounded()
            let verticalInset = max(((bounds.height - size.height) / 2).rounded(), 0)
            let insets = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)

            // setting these invalidates the layout
            if itemSize != size { itemSize = size }
            if minimumLineSpacing != spacing { minimumLineSpacing = spacing }
            if sectionInset != insets { sectionInset = insets }
        }
        super.prepare()
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)?.map(focused)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.layoutAttributesForItem(at: indexPath).map(focused)
    }

    private func focused(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let collectionView, pageWidth > 0,
              let copy = attributes.copy() as? UICollectionViewLayoutAttributes else { return attributes }

        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        let distance = min(abs(copy.center.x - centerX) / pageWidth, 1)
        let scale = 1 - (1 - sideScale) * distance
        copy.transform = CGAffineTransform(scaleX: scale, y: scale)
        copy.alpha = 1 - (1 - sideAlpha) * distance
        copy.zIndex = Int((1 - distance) * 100)
        return copy
    }
}
