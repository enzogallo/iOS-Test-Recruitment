//
//  DateFormatting+Listing.swift
//  TheGoodCorner
//
//  Parses API ISO8601 timestamps and formats them using the active UI locale.
//

import Foundation

enum ListingDateFormatting {
    private static let isoParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Presents API ISO8601 strings for the detail screen (locale-aware date/time).
    static func displayString(fromAPIDate string: String, locale: Locale = .current) -> String {
        guard let date = isoParser.date(from: string) else { return string }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = locale
        return formatter.string(from: date)
    }
}
