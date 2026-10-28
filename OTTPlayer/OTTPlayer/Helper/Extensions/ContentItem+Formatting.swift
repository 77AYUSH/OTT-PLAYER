//
//  ContentItem+Formatting.swift
//  OTTPlayer
//
//  Created by Ayush on 28/10/26.
//

import Foundation

extension ContentItem {

    var metadataText: String {
        [genre, releaseYear.map(String.init), duration?.durationText]
            .compactMap { $0 }
            .joined(separator: "  •  ")
    }

    var shortMetadataText: String {
        [genre, releaseYear.map(String.init)]
            .compactMap { $0 }
            .joined(separator: "  •  ")
    }
}
