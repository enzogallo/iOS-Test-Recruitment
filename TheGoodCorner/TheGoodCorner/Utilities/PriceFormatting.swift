//
//  PriceFormatting.swift
//  TheGoodCorner
//
//  EUR formatting follows the user’s selected app locale (French / English).
//

import Foundation

enum PriceFormatting {
    static func string(for price: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: price)) ?? "\(Int(price)) €"
    }
}
