//
//  HomeFeedDataSource.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

protocol HomeFeedDataSource {
    func fetchHomeFeed() async throws -> HomeFeedResponseDTO
}
