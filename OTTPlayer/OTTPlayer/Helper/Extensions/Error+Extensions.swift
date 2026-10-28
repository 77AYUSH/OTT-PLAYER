//
//  Error+Extensions.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

extension Error {
    var userFacingMessage: String {
        (self as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}
