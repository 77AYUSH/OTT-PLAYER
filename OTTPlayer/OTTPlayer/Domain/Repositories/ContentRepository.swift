//
//  ContentRepository.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

protocol ContentRepository {
    func fetchHomeFeed() async throws -> HomeFeed
    func fetchContent(id: String) async throws -> ContentItem
}
