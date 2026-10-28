//
//  JsonHelper.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

enum JsonHelper {

    static func loadFile(named name: String, bundle: Bundle = .main) throws -> Data {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw NetworkError.fileNotFound(name: name)
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw NetworkError.fileNotFound(name: name)
        }
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(type, from: data)
        } catch {
            AppLogger.data.error("Decoding \(String(describing: T.self), privacy: .public) failed: \(String(describing: error), privacy: .public)")
            throw NetworkError.decodingFailed
        }
    }
}
