//
//  TimeInterval+Extensions.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

extension TimeInterval {

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.maximumUnitCount = 2
        return formatter
    }()

    private static let timecodeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    var durationText: String? {
        guard isFinite, self > 0 else { return nil }
        return Self.durationFormatter.string(from: self)
    }

    var timecodeText: String? {
        guard isFinite, self > 0 else { return nil }
        let formatter = Self.timecodeFormatter
        formatter.allowedUnits = self >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        let text = formatter.string(from: self)
        // "00:52" -> "0:52"
        if let text, text.hasPrefix("0"), text.count > 4 {
            return String(text.dropFirst())
        }
        return text
    }
}
