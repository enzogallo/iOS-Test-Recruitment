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

    func testListingsURLWithoutQueryParameters() throws {
        let url = try ListingEndpoint.listingsURL(baseURL: baseURL, page: nil, limit: nil, query: nil)
        XCTAssertEqual(url.absoluteString, "http://127.0.0.1:8080/listings")
    }

    func testListingsURLWithSearchQuery() throws {
        let url = try ListingEndpoint.listingsURL(baseURL: baseURL, page: nil, limit: nil, query: "vinyle")
        XCTAssertEqual(url.absoluteString, "http://127.0.0.1:8080/listings?query=vinyle")
    }

    func testListingsURLWithPaginationAndSearch() throws {
        let url = try ListingEndpoint.listingsURL(baseURL: baseURL, page: 1, limit: 20, query: "bike")
        XCTAssertTrue(url.absoluteString.contains("page=1"))
        XCTAssertTrue(url.absoluteString.contains("limit=20"))
        XCTAssertTrue(url.absoluteString.contains("query=bike"))
    }

    func testCategoriesURL() throws {
        let url = try ListingEndpoint.categoriesURL(baseURL: baseURL)
        XCTAssertEqual(url.absoluteString, "http://127.0.0.1:8080/categories")
    }

    func testAbsoluteURLFromConfiguration() {
        let config = APIConfiguration(baseURL: baseURL)
        let path = "/images/ad-small/foo.jpg"
        let resolved = config.absoluteURL(forServerRelativePath: path)
        XCTAssertEqual(resolved?.absoluteString, "http://127.0.0.1:8080/images/ad-small/foo.jpg")
    }
}
