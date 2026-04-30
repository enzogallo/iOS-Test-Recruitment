//
//  ListingDetailView.swift
//  TheGoodCorner
//
//  Full-screen detail using the `Listing` payload (no extra API call per technical brief).
//  Localized labels only; title/description body text follows API language.
//

import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    let categoryName: String
    let configuration: APIConfiguration

    @Environment(\.locale) private var locale

    private let heroCornerRadius: CGFloat = 20

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4 / 3, contentMode: .fill)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [.clear, Color.appSurface.opacity(0.92)],
                            startPoint: UnitPoint(x: 0.5, y: 0.65),
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .accessibilityHidden(true)
                    }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(PriceFormatting.string(for: listing.price, locale: locale))
                            .font(AppTypography.priceLarge())
                            .foregroundStyle(Color.appPrice)
                        Spacer(minLength: 0)
                        if listing.isUrgent {
                            Text("urgent_badge")
                                .font(AppTypography.captionStrong())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.appBrand)
                                .clipShape(Capsule())
                                .accessibilityLabel(Text("accessibility_urgent_listing"))
                        }
                    }

                    Text(listing.title)
                        .font(AppTypography.title3())
                        .foregroundStyle(Color.appNavy)
                        .fixedSize(horizontal: false, vertical: true)

                    detailChip(title: "detail_category_label", value: categoryName, systemImage: "square.grid.2x2")
                    detailChip(
                        title: "detail_posted_label",
                        value: ListingDateFormatting.displayString(fromAPIDate: listing.creationDate, locale: locale),
                        systemImage: "clock"
                    )

                    Divider()
                        .background(Color.appSecondaryText.opacity(0.3))

                    Text("detail_description_heading")
                        .font(AppTypography.headline())
                        .foregroundStyle(Color.appNavy)

                    Text(listing.description)
                        .font(AppTypography.body())
                        .foregroundStyle(Color.appNavy.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous))
                .padding(.horizontal, 16)
                .offset(y: -28)
            }
            .padding(.bottom, 24)
        }
        .background(Color.appSurface)
        .navigationBarTitleDisplayMode(.inline)
        .font(AppTypography.body())
    }

    @ViewBuilder
    private var heroImage: some View {
        let url = preferredImageURL()
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.appChip
                        ProgressView().tint(Color.appBrand)
                    }
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderHero
                @unknown default:
                    placeholderHero
                }
            }
            .accessibilityLabel(
                L10n.format("accessibility_photo_for_listing", locale: locale, listing.title)
            )
        } else {
            placeholderHero
        }
    }

    private var placeholderHero: some View {
        ZStack {
            Color.appChip
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundStyle(Color.appSecondaryText)
        }
        .accessibilityLabel(Text("accessibility_no_image"))
    }

    private func preferredImageURL() -> URL? {
        if let small = listing.imagesURL?.small,
           let u = configuration.absoluteURL(forServerRelativePath: small) {
            return u
        }
        if let thumb = listing.imagesURL?.thumb,
           let u = configuration.absoluteURL(forServerRelativePath: thumb) {
            return u
        }
        return nil
    }

    private func detailChip(title: LocalizedStringKey, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.appBrand)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption())
                    .foregroundStyle(Color.appSecondaryText)
                Text(value)
                    .font(AppTypography.subheadline(weight: .semibold))
                    .foregroundStyle(Color.appNavy)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
