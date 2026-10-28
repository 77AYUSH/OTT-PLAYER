//
//  ImageLoader.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

@MainActor
final class ImageLoader {

    static let shared = ImageLoader()

    private let networkManager: NetworkManager
    private let cache = NSCache<NSURL, UIImage>()
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024
    }

    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = cachedImage(for: url) {
            return cached
        }
        if let existingTask = inFlightTasks[url] {
            return try await existingTask.value
        }

        let networkManager = networkManager
        // detached so a reused cell going away doesn't cancel the shared download
        let task = Task.detached(priority: .userInitiated) { () throws -> UIImage in
            let data = try await networkManager.data(from: url)
            guard let image = UIImage(data: data) else {
                throw NetworkError.decodingFailed
            }
            return image.preparingForDisplay() ?? image
        }
        inFlightTasks[url] = task
        defer { inFlightTasks[url] = nil }

        let image = try await task.value
        cache.setObject(image, forKey: url as NSURL, cost: image.approximateByteCount)
        return image
    }
}

private extension UIImage {
    var approximateByteCount: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
