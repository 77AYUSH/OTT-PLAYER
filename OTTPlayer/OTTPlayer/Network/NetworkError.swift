//
//  NetworkError.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

enum NetworkError: Error, Equatable {
    case noInternet
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case fileNotFound(name: String)
    case decodingFailed
    case unknown(message: String)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "You appear to be offline. Check your connection and try again."
        case .invalidURL:
            return "The content address is invalid."
        case .invalidResponse:
            return "The server sent an unexpected response."
        case .serverError(let statusCode):
            return "The server returned an error (\(statusCode))."
        case .fileNotFound:
            return "We couldn't find the catalogue right now."
        case .decodingFailed:
            return "The catalogue couldn't be read."
        case .unknown(let message):
            return message
        }
    }
}

extension NetworkError {
    static func from(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        if error is DecodingError {
            return .decodingFailed
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return .noInternet
            case .badURL, .unsupportedURL:
                return .invalidURL
            default:
                return .unknown(message: urlError.localizedDescription)
            }
        }
        return .unknown(message: error.localizedDescription)
    }
}
