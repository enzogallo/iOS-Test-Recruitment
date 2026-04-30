//
//  Listing.swift
//  TheGoodCorner
//
//  Created by Enzo Gallo on 29/04/2026.
//
//  Codable models mirroring `server/swagger.yaml`. JSON uses snake_case; Swift properties use camelCase
//  via explicit `CodingKeys` so decoding stays explicit and grep-friendly.
//

import Foundation

/// Response wrapper for `GET /listings`: stable ordering (urgent first, then newest) is defined by the server.
struct ListingFeed: Codable, Equatable {
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool
    let items: [Listing]

    enum CodingKeys: String, CodingKey {
        case total
        case page
        case limit
        case hasMore = "has_more"
        case items
    }
}

/// One classified ad line item; suitable for list rows and for pushing into a detail screen (no separate detail endpoint in the API).
struct Listing: Codable, Equatable, Identifiable {
    let id: Int
    let categoryId: Int
    let title: String
    let description: String
    /// JSON number maps to `Double` so both integer and fractional prices decode reliably.
    let price: Double
    /// Raw ISO 8601 string from the API; format for display in the UI layer when needed.
    let creationDate: String
    let isUrgent: Bool
    /// Nullable per schema when an ad has no images.
    let imagesURL: ImagesURL?

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case title
        case description
        case price
        case creationDate = "creation_date"
        case isUrgent = "is_urgent"
        case imagesURL = "images_url"
    }
}

/// Thumbnail paths as returned by the API; build absolute URLs with `APIConfiguration.absoluteURL(forServerRelativePath:)`.
struct ImagesURL: Codable, Equatable {
    let small: String?
    let thumb: String?

    enum CodingKeys: String, CodingKey {
        case small
        case thumb
    }
}

/// Maps `category_id` on listings to a human-readable label from `GET /categories`.
/// Named `ListingCategory` to avoid a name clash with other frameworks exporting `Category` (e.g. in test bundles).
struct ListingCategory: Codable, Equatable, Identifiable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
