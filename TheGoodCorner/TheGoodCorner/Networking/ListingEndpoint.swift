//
//  ListingEndpoint.swift
//  TheGoodCorner
//
//  Pure URL construction for the recruitment API. Isolated from networking so unit tests
//  can assert query strings without hitting localhost.
//

import Foundation

/// Factory for `GET` URLs defined in `server/swagger.yaml`.
enum ListingEndpoint {
    /// Builds `GET /listings` with optional `page`, `limit`, and search `query`.
    ///
    /// The OpenAPI doc states pagination params should be used together; sending only one may yield HTTP 400.
    /// - Parameters:
    ///   - baseURL: Same root as `APIConfiguration.baseURL`.
    ///   - page: 1-based page index when paginating.
    ///   - limit: Page size when paginating.
    ///   - query: Search string matched against title and description on the server.
    /// - Returns: A URL whose query items reflect only non-nil parameters (empty `query` is omitted).
    static func listingsURL(
        baseURL: URL,
        page: Int?,
        limit: Int?,
        query: String?
    ) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            throw ListingAPIError.invalidURL
        }
        components.path = "/listings"
        var items: [URLQueryItem] = []
        if let page {
            items.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let limit {
            items.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let query, !query.isEmpty {
            items.append(URLQueryItem(name: "query", value: query))
        }
        components.queryItems = items.isEmpty ? nil : items
        guard let url = components.url else { throw ListingAPIError.invalidURL }
        return url
    }

    /// Builds `GET /categories` (returns a JSON array of category objects).
    static func categoriesURL(baseURL: URL) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            throw ListingAPIError.invalidURL
        }
        components.path = "/categories"
        guard let url = components.url else { throw ListingAPIError.invalidURL }
        return url
    }
}
