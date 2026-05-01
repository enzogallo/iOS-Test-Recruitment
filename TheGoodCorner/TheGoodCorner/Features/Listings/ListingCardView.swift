//
//  ListingCardView.swift
//  TheGoodCorner
//
//  Grid cell: square photo (stable layout), Jakarta typography, localized chrome.
//  Listing title/description from the API are shown as-is (may be French).
//

import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    let categoryName: String
    let imageURL: URL?
    /// Horizontal rail preview: reserve exactly two title lines so every card has the same height (grid ignores this).
    var uniformRailHeight: Bool = false

    @Environment(\.locale) private var locale

    private let cornerRadius: CGFloat = 16

    /// Two lines of `subheadline` semibold — fixed slot so 1-line and 2-line titles don’t change card height.
    private var railTitleBlockHeight: CGFloat { 40 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            imageBlock

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(AppTypography.subheadline(weight: .semibold))
                    .foregroundStyle(Color.appNavy)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(TitleVerticalSizing(uniformRailHeight: uniformRailHeight, railTitleBlockHeight: railTitleBlockHeight))

                Text(PriceFormatting.string(for: listing.price, locale: locale))
                    .font(AppTypography.headline())
                    .foregroundStyle(Color.appPrice)

                Text(categoryName)
                    .font(AppTypography.caption())
                    .foregroundStyle(Color.appSecondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
        .padding(10)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius + 4, style: .continuous))
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelForCard)
    }

    /// Fixed aspect-ratio image area so `LazyVGrid` rows do not overlap.
    private var imageBlock: some View {
        ZStack(alignment: .topTrailing) {
            Color.appChip
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    imageLayer
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )

            if listing.isUrgent {
                Text("urgent_badge")
                    .font(AppTypography.captionStrong())
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appBrand.opacity(0.95))
                    .clipShape(Capsule())
                    .padding(8)
                    .accessibilityLabel(Text("accessibility_urgent_listing"))
            }
        }
    }

    @ViewBuilder
    private var imageLayer: some View {
        if let imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(Color.appBrand)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                case .failure:
                    imageFailure
                @unknown default:
                    ProgressView()
                        .tint(Color.appBrand)
                }
            }
            .accessibilityLabel(L10n.format("accessibility_listing_image", locale: locale, listing.title))
        } else {
            imageFailure
        }
    }

    private var imageFailure: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(Color.appSecondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(Text("accessibility_no_image"))
    }

    private var accessibilityLabelForCard: String {
        let price = PriceFormatting.string(for: listing.price, locale: locale)
        var parts = [listing.title, price, categoryName]
        if listing.isUrgent {
            parts.append(L10n.string("urgent_badge", locale: locale))
        }
        return parts.joined(separator: ", ")
    }
}

private struct TitleVerticalSizing: ViewModifier {
    let uniformRailHeight: Bool
    let railTitleBlockHeight: CGFloat

    func body(content: Content) -> some View {
        if uniformRailHeight {
            content
                .frame(height: railTitleBlockHeight, alignment: .top)
        } else {
            content
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
