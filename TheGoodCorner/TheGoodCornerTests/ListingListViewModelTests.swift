//
//  ListingListViewModelTests.swift
//  TheGoodCornerTests
//
//  Rails, multi-select visibility, and fetch supersession — no local server (stub `ListingAPIClient`).
//

import XCTest
@testable import TheGoodCorner

// MARK: - Stubs

private func listing(
    id: Int,
    categoryId: Int,
    title: String = "t"
) -> Listing {
    Listing(
        id: id,
        categoryId: categoryId,
        title: title,
        description: "",
        price: 1,
        creationDate: "2020-01-01T00:00:00Z",
        isUrgent: false,
        imagesURL: nil
    )
}

private func feed(items: [Listing]) -> ListingFeed {
    ListingFeed(total: items.count, page: 1, limit: 100, hasMore: false, items: items)
}

/// Immediate responses; used for rail / filter assertions.
private actor StubListingAPIClient: ListingAPIClient {
    private let categories: [ListingCategory]
    private let listingFeed: ListingFeed

    init(categories: [ListingCategory], listingFeed: ListingFeed) {
        self.categories = categories
        self.listingFeed = listingFeed
    }

    func fetchListingFeed(page: Int?, limit: Int?, query: String?) async throws -> ListingFeed {
        listingFeed
    }

    func fetchCategories() async throws -> [ListingCategory] {
        categories
    }
}

/// First feed call waits (cancellable); later calls return immediately — exercises superseded fetch.
private actor DelayingThenFastListingAPIClient: ListingAPIClient {
    private var feedCallCount = 0
    private let categories: [ListingCategory]
    private let slowFeed: ListingFeed
    private let fastFeed: ListingFeed

    init(categories: [ListingCategory], slowFeed: ListingFeed, fastFeed: ListingFeed) {
        self.categories = categories
        self.slowFeed = slowFeed
        self.fastFeed = fastFeed
    }

    func fetchListingFeed(page: Int?, limit: Int?, query: String?) async throws -> ListingFeed {
        feedCallCount += 1
        if feedCallCount == 1 {
            try await Task.sleep(nanoseconds: 400_000_000)
            return slowFeed
        }
        return fastFeed
    }

    func fetchCategories() async throws -> [ListingCategory] {
        categories
    }
}

// MARK: - Tests

final class ListingListViewModelTests: XCTestCase {
    private let baseURL = URL(string: "http://127.0.0.1:8080")!
    private let locale = Locale(identifier: "fr_FR")

    /// **Subject:** `ListingListViewModel.categoryRailSections(locale:)` after `load()`.
    /// **Checks:** rails are ordered by localized category name; listings whose `category_id` is absent from the API map appear under a synthetic “Other” rail (`id == -1`).
    @MainActor
    func testCategoryRailsSortByCategoryNameAndBucketUnknownCategoryIds() async throws {
        let categories = [
            ListingCategory(id: 2, name: "B"),
            ListingCategory(id: 1, name: "A"),
        ]
        let items = [
            listing(id: 10, categoryId: 1),
            listing(id: 20, categoryId: 99),
            listing(id: 30, categoryId: 1),
        ]
        let stub = StubListingAPIClient(categories: categories, listingFeed: feed(items: items))
        let vm = ListingListViewModel(apiClient: stub, configuration: APIConfiguration(baseURL: baseURL))
        await vm.load()

        let rails = vm.categoryRailSections(locale: locale)
        XCTAssertEqual(rails.map(\.id), [1, -1], "Known categories sorted by name, then “Other” for unknown ids.")
        XCTAssertEqual(rails.first?.listings.map(\.id), [10, 30])
        XCTAssertEqual(rails.last?.listings.map(\.id), [20])
    }

    /// **Subject:** `trimmedSearchQuery`, `toggleCategoryFilter`, `clearCategoryFilters`, and `visibleCategoryRailSections(locale:)`.
    /// **Checks:** search text is trimmed for API use; when no category filter is active, all rails stay visible; toggling on/off narrows or restores rails as expected.
    @MainActor
    func testVisibleRailsFilterBySelectedCategoryIds() async throws {
        let categories = [
            ListingCategory(id: 1, name: "A"),
            ListingCategory(id: 2, name: "B"),
        ]
        let items = [listing(id: 1, categoryId: 1), listing(id: 2, categoryId: 2)]
        let stub = StubListingAPIClient(categories: categories, listingFeed: feed(items: items))
        let vm = ListingListViewModel(apiClient: stub, configuration: APIConfiguration(baseURL: baseURL))

        vm.searchText = "  promo  "
        XCTAssertEqual(vm.trimmedSearchQuery, "promo")
        vm.searchText = "   "
        XCTAssertNil(vm.trimmedSearchQuery)

        await vm.load()

        XCTAssertEqual(vm.visibleCategoryRailSections(locale: locale).map(\.id), [1, 2])

        vm.toggleCategoryFilter(2)
        XCTAssertEqual(vm.visibleCategoryRailSections(locale: locale).map(\.id), [2])

        vm.toggleCategoryFilter(1)
        XCTAssertEqual(vm.visibleCategoryRailSections(locale: locale).map(\.id), [1, 2])

        vm.clearCategoryFilters()
        XCTAssertEqual(vm.visibleCategoryRailSections(locale: locale).map(\.id), [1, 2])
    }

    /// **Subject:** overlapping `load()` calls when the first network response is slower than the second (`DelayingThenFastListingAPIClient`).
    /// **Checks:** only the latest completed fetch updates `listings`; the delayed first response must not overwrite newer data or surface `loadError`.
    @MainActor
    func testSupersededFetchDoesNotApplyFirstResponseAfterSecondLoad() async throws {
        let categories = [ListingCategory(id: 1, name: "A")]
        let slow = feed(items: [listing(id: 1, categoryId: 1, title: "slow")])
        let fast = feed(items: [listing(id: 2, categoryId: 1, title: "fast")])
        let api = DelayingThenFastListingAPIClient(categories: categories, slowFeed: slow, fastFeed: fast)
        let vm = ListingListViewModel(apiClient: api, configuration: APIConfiguration(baseURL: baseURL))

        let first = Task { await vm.load() }
        try await Task.sleep(nanoseconds: 50_000_000)
        await vm.load()
        await first.value

        XCTAssertEqual(vm.listings.map(\.id), [2])
        XCTAssertEqual(vm.listings.first?.title, "fast")
        XCTAssertNil(vm.loadError)
    }
}
