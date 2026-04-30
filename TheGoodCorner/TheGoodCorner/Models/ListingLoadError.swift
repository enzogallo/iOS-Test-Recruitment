//
//  ListingLoadError.swift
//  TheGoodCorner
//
//  Typed API failures surfaced in the UI. Copy stays localized in views / `L10n`
//  using the active `Locale` (system language / Settings).
//

import Foundation

enum ListingLoadError: Equatable {
    case generic
    case httpStatus(Int)
    case transport(Int)
}
