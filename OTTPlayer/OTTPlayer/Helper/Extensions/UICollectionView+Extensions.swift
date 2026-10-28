//
//  UICollectionView+Extensions.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

// MARK: - Reuse identifier
extension UICollectionReusableView {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}

// MARK: - Registration
extension UICollectionView {
    func register<T: UICollectionViewCell>(cell: T.Type) {
        let nib = UINib(nibName: T.reuseIdentifier, bundle: Bundle(for: T.self))
        register(nib, forCellWithReuseIdentifier: T.reuseIdentifier)
    }

    func registerHeader<T: UICollectionReusableView>(header: T.Type) {
        let nib = UINib(nibName: T.reuseIdentifier, bundle: Bundle(for: T.self))
        register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: T.reuseIdentifier)
    }
}

// MARK: - Dequeue
extension UICollectionView {
    func dequeue<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("\(T.reuseIdentifier) is not registered")
        }
        return cell
    }

    func dequeueHeader<T: UICollectionReusableView>(for indexPath: IndexPath) -> T {
        guard let header = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("\(T.reuseIdentifier) is not registered")
        }
        return header
    }
}
