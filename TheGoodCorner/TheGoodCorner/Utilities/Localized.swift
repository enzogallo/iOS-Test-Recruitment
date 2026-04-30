//
//  Localized.swift
//  TheGoodCorner
//
//  Thin helpers around String(localized:) so ViewModels and views stay readable.
//  UI strings live in fr.lproj / en.lproj; resolution follows the system / Settings.
//

import Foundation

enum L10n {
    static func string(_ key: String, locale: Locale? = nil) -> String {
        if let locale {
            return String(localized: String.LocalizationValue(key), locale: locale)
        }
        return String(localized: String.LocalizationValue(key))
    }

    /// Keys such as `accessibility_listing_image` use `%@` in the strings files.
    static func format(_ key: String, locale: Locale, _ arg: String) -> String {
        let template = string(key, locale: locale)
        return String(format: template, locale: locale, arg)
    }

    static func categoryFallback(categoryId: Int, locale: Locale) -> String {
        let format = string("listing_category_fallback", locale: locale)
        return String(format: format, locale: locale, categoryId)
    }

    static func loadErrorMessage(for error: ListingLoadError, locale: Locale) -> String {
        switch error {
        case .generic:
            return string("error_generic_detail", locale: locale)
        case let .httpStatus(code):
            let format = string("error_http_format", locale: locale)
            return String(format: format, locale: locale, code)
        case let .transport(code):
            let format = string("error_transport_format", locale: locale)
            return String(format: format, locale: locale, code)
        }
    }
}
