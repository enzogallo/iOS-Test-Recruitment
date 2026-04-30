//
//  ListingListViewModel.swift
//  TheGoodCorner
//
//  Loads listings and categories from `ListingAPIClient`. Search uses the server `query`
//  parameter (debounced in the view). Category filtering is client-side on the current result set.
//  User-visible error copy is localized in the view via `ListingLoadError` + `L10n`.
//

import Combine
import Foundation

@MainActor
final class ListingListViewModel: ObservableObject {
    @Published private(set) var listings: [Listing] = []
    @Published private(set) var categories: [ListingCategory] = []
    @Published private(set) var isLoading = false
    /// Populated when the feed cannot be loaded; map to strings with `L10n.loadErrorMessage` in the view.
    @Published private(set) var loadError: ListingLoadError?
    /// Bound to the search field; debounced network refresh applies when this changes.
    @Published var searchText = ""
    /// When non-nil, filters `displayedListings` by category client-side.
    @Published var selectedCategoryId: Int?

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

    /// Listings to show: same order as the API, optionally filtered by category.
    var displayedListings: [Listing] {
        guard let id = selectedCategoryId else { return listings }
        return listings.filter { $0.categoryId == id }
    }

    /// Resolved category label for chips and rows; uses localized fallback when the API name is missing.
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
        let query = preserveSearchQuery ? normalizedSearchQuery : nil
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

    private var normalizedSearchQuery: String? {
        let t = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
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
