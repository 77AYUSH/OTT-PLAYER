//
//  ContentError.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

enum ContentError: Error, Equatable {
    case notFound(id: String)
}

extension ContentError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "This title is no longer available."
        }
    }
}
