//
//  UIImageView+Extensions.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit
import ObjectiveC

private var imageLoadTaskKey: UInt8 = 0

extension UIImageView {

    func setImage(from url: URL?) {
        cancelImageLoad()

        guard let url else {
            showPlaceholder(Constants.Images.failure)
            return
        }
        if let cached = ImageLoader.shared.cachedImage(for: url) {
            showLoadedImage(cached, animated: false)
            return
        }

        showPlaceholder(Constants.Images.placeholder)
        imageLoadTask = Task { [weak self] in
            do {
                let image = try await ImageLoader.shared.image(for: url)
                guard !Task.isCancelled else { return }
                self?.showLoadedImage(image, animated: true)
            } catch {
                guard !Task.isCancelled else { return }
                self?.showPlaceholder(Constants.Images.failure)
            }
        }
    }

    func cancelImageLoad() {
        imageLoadTask?.cancel()
        imageLoadTask = nil
    }

    private var imageLoadTask: Task<Void, Never>? {
        get { objc_getAssociatedObject(self, &imageLoadTaskKey) as? Task<Void, Never> }
        set { objc_setAssociatedObject(self, &imageLoadTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private func showPlaceholder(_ placeholder: UIImage?) {
        contentMode = .center
        tintColor = Constants.Colors.secondaryText
        image = placeholder
    }

    private func showLoadedImage(_ loadedImage: UIImage, animated: Bool) {
        contentMode = .scaleAspectFill
        guard animated else {
            image = loadedImage
            return
        }
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
            self.image = loadedImage
        }
    }
}
