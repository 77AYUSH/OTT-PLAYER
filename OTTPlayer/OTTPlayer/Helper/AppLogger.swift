//
//  AppLogger.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import os

enum AppLogger {
    private static let subsystem = "com.ayushgandhi.OTTPlayer"

    static let data = Logger(subsystem: subsystem, category: "data")
    static let player = Logger(subsystem: subsystem, category: "player")
    static let analytics = Logger(subsystem: subsystem, category: "analytics")
}
