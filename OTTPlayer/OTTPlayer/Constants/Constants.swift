//
//  Constants.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import UIKit

enum Constants {

    // launch with -homeFeedFile missing_feed to test the error state
    static var homeFeedFileName: String {
        UserDefaults.standard.string(forKey: "homeFeedFile") ?? "home_feed"
    }

    static let simulatedFeedLatency: UInt64 = 400_000_000

    enum Colors {
        static let background = UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1)
        static let surface = UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1)
        static let cardBorder = UIColor(white: 1, alpha: 0.08)
        static let accent = UIColor(red: 0.36, green: 0.47, blue: 1.0, alpha: 1)
        static let primaryText = UIColor.white
        static let secondaryText = UIColor(white: 0.72, alpha: 1)
    }

    enum Images {
        static let placeholder = UIImage(systemName: "film", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .light))
        static let failure = UIImage(systemName: "exclamationmark.triangle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .light))
    }

    enum Home {
        static let carouselAutoScrollInterval: TimeInterval = 5
    }

    enum Player {
        static let progressInterval: TimeInterval = 0.5
        static let seekThreshold: TimeInterval = 1.0
        static let seekDebounce: TimeInterval = 0.4
        static let endOfItemTolerance: TimeInterval = 0.5
    }
}
