//
//  TheGoodCornerTests.swift
//  TheGoodCornerTests
//
//  Codable round-trip tests using bundled JSON fixtures—no network or running server required.
//

import XCTest
@testable import TheGoodCorner

/// How this target works (quick mental model):
/// - **XCTest** runs methods whose names start with `test` on subclasses of `XCTestCase`.
/// - `XCTAssert*` checks expectations; if one fails, the test turns red and shows the message.
/// - Tests run in the **simulator or Mac** (host) without you tapping the app; they are meant to be **deterministic** (no live server for our decoding tests).
final class ListingFeedDecodingTests: XCTestCase {

    /// Loads a JSON file that was added to the **TheGoodCornerTests** target (same folder / Resources).
    /// If Xcode cannot find the file, we get a clear failure — usually means the file is not in the test bundle (target membership).
    private func loadListingFeedFixture() throws -> Data {
        let bundle = Bundle(for: ListingFeedDecodingTests.self)
        if let url = bundle.url(forResource: "listing_feed_fixture", withExtension: "json", subdirectory: "Resources")
            ?? bundle.url(forResource: "listing_feed_fixture", withExtension: "json") {
            return try Data(contentsOf: url)
        }
        XCTFail("Could not find listing_feed_fixture.json in test bundle \(bundle.bundlePath)")
        throw NSError(domain: "Tests", code: 0)
    }

    /// **Subject:** `ListingFeed` + nested `Listing` match the JSON envelope from `GET /listings` (`listing_feed_fixture.json`).
    /// **Checks:** envelope fields (`page`, `total`, `items`), first item fields (`id`, `category_id`, `price`, dates, `images_url.small`).
    func testListingFeedDecodesFromFixture() throws {
        let data = try loadListingFeedFixture()
        let decoder = JSONDecoder()
        let feed = try decoder.decode(ListingFeed.self, from: data)

        XCTAssertEqual(feed.page, 1)
        XCTAssertEqual(feed.total, 300)
        XCTAssertEqual(feed.items.count, 1)

        let first = try XCTUnwrap(feed.items.first)
        XCTAssertEqual(first.id, 1547408955)
        XCTAssertEqual(first.categoryId, 7)
        XCTAssertTrue(first.isUrgent)
        XCTAssertEqual(first.price, 10, accuracy: 0.001)
        XCTAssertEqual(first.creationDate, "2019-11-06T11:22:35Z")
        XCTAssertNotNil(first.imagesURL?.small)
    }

    /// **Subject:** decoding a raw JSON **array** (not an object envelope), same shape as `GET /categories`.
    /// **Checks:** `Array<ListingCategory>` decodes; `id` and `name` map from snake-free keys.
    func testCategoryArrayDecodesFromInlineJSON() throws {
        let json = try XCTUnwrap(
            """
            [
              {"id": 1, "name": "Vehicule"},
              {"id": 8, "name": "Multimedia"}
            ]
            """.data(using: .utf8)
        )

        let categories = try JSONDecoder().decode(Array<ListingCategory>.self, from: json)

        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0].id, 1)
        XCTAssertEqual(categories[1].name, "Multimedia")
    }
}
