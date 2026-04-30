//
//  ListingAPIError.swift
//  TheGoodCorner
//
//  Typed errors for the listing HTTP layer so the UI can branch without inspecting raw URLError codes.
//

import Foundation

/// Errors raised by `DefaultListingAPIClient` when building URLs, performing requests, or decoding JSON.
enum ListingAPIError: Error, Equatable {
    /// `URLComponents` failed to produce a valid URL (misconfigured base or path).
    case invalidURL
    /// The session returned a response that was not an `HTTPURLResponse`.
    case invalidHTTPResponse
    /// Status code was outside 2xx (e.g. 400 for bad query params, 404, 500).
    case httpStatus(code: Int)
    /// Response body could not be decoded into `ListingFeed` or `[ListingCategory]`.
    case decodingFailed
    /// Low-level failure (`URLError`); `underlyingCode` is `URLError.Code.rawValue`, or `-1` for unknown transport errors.
    case transport(underlyingCode: Int)

    static func == (lhs: ListingAPIError, rhs: ListingAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidHTTPResponse, .invalidHTTPResponse),
             (.decodingFailed, .decodingFailed):
            return true
        case let (.httpStatus(a), .httpStatus(b)):
            return a == b
        case let (.transport(a), .transport(b)):
            return a == b
        default:
            return false
        }
    }
}
