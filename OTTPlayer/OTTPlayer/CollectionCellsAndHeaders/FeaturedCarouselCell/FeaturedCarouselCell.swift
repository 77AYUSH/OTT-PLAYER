//
//  FeaturedCarouselCell.swift
//  OTTPlayer
//
//  Created by Ayush on 28/10/26.
//

import UIKit

final class FeaturedCarouselCell: UICollectionViewCell {

    private static let verticalPadding: CGFloat = 16
    private static let pageControlHeight: CGFloat = 26

    static func height(forWidth width: CGFloat) -> CGFloat {
        CarouselFlowLayout.itemSize(forContainerWidth: width).height + verticalPadding * 2 + pageControlHeight
    }

    // MARK: - IBOutlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!

    var onSelect: ((ContentItem) -> Void)?

    private let carouselLayout = CarouselFlowLayout()
    private var items: [ContentItem] = []
    private var autoScrollTimer: Timer?
    private var isAutoScrollRequested = false
    // page from the last settled card, a fast flick can move the offset before the drag begins
    private var settledIndex = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.collectionViewLayout = carouselLayout
        collectionView.register(cell: CarouselCardCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.clipsToBounds = false

        pageControl.currentPageIndicatorTintColor = Constants.Colors.primaryText
        pageControl.pageIndicatorTintColor = Constants.Colors.primaryText.withAlphaComponent(0.3)
        pageControl.hidesForSinglePage = true
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
    }

    deinit {
        autoScrollTimer?.invalidate()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAutoScroll()
        onSelect = nil
    }

    func configure(with items: [ContentItem]) {
        pageControl.numberOfPages = items.count
        guard items != self.items else { return }
        self.items = items
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(.zero, animated: false)
        settledIndex = 0
        pageControl.currentPage = 0
    }

    @objc private func pageControlChanged() {
        scroll(to: pageControl.currentPage, animated: true)
        scheduleAutoScroll()
    }
}

// MARK: - Auto-scroll
extension FeaturedCarouselCell {

    func startAutoScroll() {
        isAutoScrollRequested = true
        scheduleAutoScroll()
    }

    func stopAutoScroll() {
        isAutoScrollRequested = false
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func scheduleAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        guard isAutoScrollRequested, items.count > 1, !UIAccessibility.isReduceMotionEnabled else { return }

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: Constants.Home.carouselAutoScrollInterval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.advanceToNextCard()
            }
        }
    }

    private func advanceToNextCard() {
        let nextIndex = (settledIndex + 1) % items.count
        scroll(to: nextIndex, animated: true)
        scheduleAutoScroll()
    }

    private var currentIndex: Int {
        guard carouselLayout.pageWidth > 0, !items.isEmpty else { return 0 }
        let index = Int((collectionView.contentOffset.x / carouselLayout.pageWidth).rounded())
        return min(max(index, 0), items.count - 1)
    }

    private func scroll(to index: Int, animated: Bool) {
        settledIndex = index
        let offset = CGPoint(x: CGFloat(index) * carouselLayout.pageWidth, y: 0)
        collectionView.setContentOffset(offset, animated: animated)
    }
}

// MARK: - Collection view
extension FeaturedCarouselCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CarouselCardCell = collectionView.dequeue(for: indexPath)
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item == settledIndex else {
            scroll(to: indexPath.item, animated: true)
            scheduleAutoScroll()
            return
        }
        onSelect?(items[indexPath.item])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl.currentPage = currentIndex
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    // always move exactly one card, however hard the swipe
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let startIndex = settledIndex
        var index: Int
        if velocity.x > 0.2 {
            index = startIndex + 1
        } else if velocity.x < -0.2 {
            index = startIndex - 1
        } else {
            index = currentIndex
        }
        index = min(max(index, startIndex - 1, 0), min(startIndex + 1, items.count - 1))
        settledIndex = index
        targetContentOffset.pointee = CGPoint(x: CGFloat(index) * carouselLayout.pageWidth, y: 0)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scheduleAutoScroll()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scheduleAutoScroll()
    }
}
