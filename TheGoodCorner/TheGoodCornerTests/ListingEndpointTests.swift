//
//  ListingEndpointTests.swift
//  TheGoodCornerTests
//
//  Validates URL construction and image path resolution without running the local server.
//

import XCTest
@testable import TheGoodCorner

final class ListingEndpointTests: XCTestCase {

    /// Same shape as `APIConfiguration.defaultSimulator`; explicit host keeps assertions readable.
    private let baseURL = URL(string: "http://127.0.0.1:8080")!

    /// **Subject:** `ListingEndpoint.listingsURL` with a non-empty `query`.
    /// **Checks:** path `/listings` and exactly one `query` query item matching the search term.
    func testListingsURLWithSearchQuery() throws {
        let url = try ListingEndpoint.listingsURL(baseURL: baseURL, page: nil, limit: nil, query: "vinyle")
        XCTAssertEqual(url.absoluteString, "http://127.0.0.1:8080/listings?query=vinyle")
    }

    /// **Subject:** `ListingEndpoint.listingsURL` when `query` is `nil` (no server-side search).
    /// **Checks:** URL has path `/listings` and **no** `query=` parameter.
    func testListingsURLOmitsQueryWhenNil() throws {
        let url = try ListingEndpoint.listingsURL(baseURL: baseURL, page: nil, limit: nil, query: nil)
        XCTAssertEqual(url.absoluteString, "http://127.0.0.1:8080/listings")
    }

    /// **Subject:** `ListingEndpoint.categoriesURL`.
    /// **Checks:** absolute URL ends with `/categories` for the given base URL.
    func testCategoriesURL() throws {
        let url = try ListingEndpoint.categoriesURL(baseURL: baseURL)
        XCTAssertEqual(url.absoluteString, "http://127.0.0.1:8080/categories")
    }

    /// **Subject:** `APIConfiguration.absoluteURL(forServerRelativePath:)` for a typical image path from the feed.
    /// **Checks:** server-relative `/images/...` resolves under `baseURL` with correct host and scheme.
    func testAbsoluteURLFromConfiguration() {
        let config = APIConfiguration(baseURL: baseURL)
        let path = "/images/ad-small/foo.jpg"
        let resolved = config.absoluteURL(forServerRelativePath: path)
        XCTAssertEqual(resolved?.absoluteString, "http://127.0.0.1:8080/images/ad-small/foo.jpg")
    }
}
