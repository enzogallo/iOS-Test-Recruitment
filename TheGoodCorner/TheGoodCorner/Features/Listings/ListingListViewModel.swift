//
//  ListingListViewModel.swift
//  TheGoodCorner
//
//  Loads listings and categories from `ListingAPIClient`. Search uses the server `query`
//  (debounced in the view). Rails + optional multi-select filters; user-facing errors via `L10n`.
//

import Combine
import Foundation

/// One category rail (`/categories` or “Other” for unknown `category_id`). `id == -1` is the orphan bucket.
struct CategoryRailSection: Identifiable {
    let id: Int
    let title: String
    /// Same relative order as listings from the API within this bucket.
    let listings: [Listing]
}

@MainActor
final class ListingListViewModel: ObservableObject {
    @Published private(set) var listings: [Listing] = []
    @Published private(set) var categories: [ListingCategory] = []
    @Published private(set) var isLoading = false
    /// Populated when the feed cannot be loaded; map to strings with `L10n.loadErrorMessage` in the view.
    @Published private(set) var loadError: ListingLoadError?
    /// Bound to the search field; debounced network refresh applies when this changes.
    @Published var searchText = ""
    /// Empty = show all rails; otherwise only sections whose `id` is in the set.
    @Published private(set) var selectedCategoryIds: Set<Int> = []

    /// Trimmed `searchText`, non-nil when the API `query` parameter should be sent.
    var trimmedSearchQuery: String? {
        let t = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private let apiClient: ListingAPIClient
    let configuration: APIConfiguration

    private var searchDebounceTask: Task<Void, Never>?

    init(
        apiClient: ListingAPIClient = DefaultListingAPIClient(),
        configuration: APIConfiguration = APIConfiguration(
            baseURL: URL(string: "http://127.0.0.1:8080")!
        )
    ) {
        self.apiClient = apiClient
        self.configuration = configuration
    }

    /// Groups `listings` by `category_id` using names from `categories`; unknown ids go to an **Other** rail.
    func categoryRailSections(locale: Locale) -> [CategoryRailSection] {
        guard !listings.isEmpty else { return [] }

        let knownIds = Set(categories.map(\.id))
        var buckets: [Int: [Listing]] = [:]
        var orphans: [Listing] = []

        for listing in listings {
            if knownIds.contains(listing.categoryId) {
                buckets[listing.categoryId, default: []].append(listing)
            } else {
                orphans.append(listing)
            }
        }

        var sections: [CategoryRailSection] = []
        for category in categories {
            if let items = buckets[category.id], !items.isEmpty {
                sections.append(CategoryRailSection(id: category.id, title: category.name, listings: items))
            }
        }

        if !orphans.isEmpty {
            sections.append(
                CategoryRailSection(
                    id: -1,
                    title: L10n.string("section_other_category", locale: locale),
                    listings: orphans
                )
            )
        }

        return sections
    }

    /// Rails after applying `selectedCategoryIds` (no-op when the set is empty).
    func visibleCategoryRailSections(locale: Locale) -> [CategoryRailSection] {
        let all = categoryRailSections(locale: locale)
        guard !selectedCategoryIds.isEmpty else { return all }
        return all.filter { selectedCategoryIds.contains($0.id) }
    }

    func clearCategoryFilters() {
        selectedCategoryIds = []
    }

    func toggleCategoryFilter(_ categoryId: Int) {
        var next = selectedCategoryIds
        if next.contains(categoryId) {
            next.remove(categoryId)
        } else {
            next.insert(categoryId)
        }
        selectedCategoryIds = next
    }

    /// Resolved category label for cards and detail; uses localized fallback when the API name is missing.
    func categoryDisplayName(for listing: Listing, locale: Locale) -> String {
        if let name = categories.first(where: { $0.id == listing.categoryId })?.name {
            return name
        }
        return L10n.categoryFallback(categoryId: listing.categoryId, locale: locale)
    }

    func load() async {
        await fetchListings(preserveSearchQuery: true)
    }

    func retry() async {
        await fetchListings(preserveSearchQuery: true)
    }

    /// Invoked when `searchText` changes from the view; waits then refetches with `query` (server-side search).
    func searchTextDidChange() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await fetchListings(preserveSearchQuery: true)
        }
    }

    private func fetchListings(preserveSearchQuery: Bool) async {
        isLoading = true
        loadError = nil
        let query = preserveSearchQuery ? trimmedSearchQuery : nil
        do {
            async let categoriesTask = apiClient.fetchCategories()
            async let feedTask = apiClient.fetchListingFeed(page: nil, limit: nil, query: query)
            let (fetchedCategories, feed) = try await (categoriesTask, feedTask)
            categories = fetchedCategories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            listings = feed.items
        } catch {
            loadError = mapLoadError(from: error)
        }
        isLoading = false
    }

    private func mapLoadError(from error: Error) -> ListingLoadError {
        if let api = error as? ListingAPIError {
            switch api {
            case .invalidURL, .invalidHTTPResponse, .decodingFailed:
                return .generic
            case let .httpStatus(code):
                return .httpStatus(code)
            case let .transport(code):
                return .transport(code)
            }
        }
        return .generic
    }
}
