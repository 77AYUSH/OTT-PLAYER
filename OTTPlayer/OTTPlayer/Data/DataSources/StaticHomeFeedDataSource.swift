//
//  StaticHomeFeedDataSource.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

final class StaticHomeFeedDataSource: HomeFeedDataSource {

    private let fileName: String
    private let bundle: Bundle
    private let simulatedLatency: UInt64

    init(fileName: String, bundle: Bundle = .main, simulatedLatency: UInt64 = 0) {
        self.fileName = fileName
        self.bundle = bundle
        self.simulatedLatency = simulatedLatency
    }

    func fetchHomeFeed() async throws -> HomeFeedResponseDTO {
        if simulatedLatency > 0 {
            try await Task.sleep(nanoseconds: simulatedLatency)
        }
        let data = try JsonHelper.loadFile(named: fileName, bundle: bundle)
        return try JsonHelper.decode(HomeFeedResponseDTO.self, from: data)
    }
}
