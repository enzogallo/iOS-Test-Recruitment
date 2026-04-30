//
//  ListingAPIClient.swift
//  TheGoodCorner
//
//  Async HTTP access to the local test server. Inject a custom `URLSession` in tests to stub responses.
//

import Foundation

/// Abstraction over listing feed and category fetches; keeps view models testable with mock implementations.
protocol ListingAPIClient: Sendable {
    /// Loads the listing envelope (items + pagination metadata). Pass `query` for server-side search.
    func fetchListingFeed(page: Int?, limit: Int?, query: String?) async throws -> ListingFeed

    /// Loads all categories for filters and display names.
    func fetchCategories() async throws -> [ListingCategory]
}

/// Production implementation using `URLSession` and `JSONDecoder` with models from `Listing.swift`.
struct DefaultListingAPIClient: ListingAPIClient {
    private let configuration: APIConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    /// - Parameters:
    ///   - configuration: Base URL; defaults to the simulator loopback.
    ///   - session: Defaults to `.shared`; replace with a stub session in unit tests if needed.
    nonisolated init(configuration: APIConfiguration = .defaultSimulator, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchListingFeed(page: Int?, limit: Int?, query: String?) async throws -> ListingFeed {
        let url = try ListingEndpoint.listingsURL(
            baseURL: configuration.baseURL,
            page: page,
            limit: limit,
            query: query
        )
        let data = try await loadGET(url: url)
        do {
            return try decoder.decode(ListingFeed.self, from: data)
        } catch {
            throw ListingAPIError.decodingFailed
        }
    }

    func fetchCategories() async throws -> [ListingCategory] {
        let url = try ListingEndpoint.categoriesURL(baseURL: configuration.baseURL)
        let data = try await loadGET(url: url)
        do {
            return try decoder.decode(Array<ListingCategory>.self, from: data)
        } catch {
            throw ListingAPIError.decodingFailed
        }
    }

    /// Performs a GET, validates HTTP status, returns raw body data for decoding.
    /// Maps `URLError` to `ListingAPIError.transport` so callers see a single error type.
    private func loadGET(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw ListingAPIError.invalidHTTPResponse
            }
            guard (200...299).contains(http.statusCode) else {
                throw ListingAPIError.httpStatus(code: http.statusCode)
            }
            return data
        } catch let error as ListingAPIError {
            throw error
        } catch let urlError as URLError {
            throw ListingAPIError.transport(underlyingCode: urlError.code.rawValue)
        } catch {
            throw ListingAPIError.transport(underlyingCode: -1)
        }
    }
}
