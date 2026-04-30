//
//  ListingDetailView.swift
//  TheGoodCorner
//
//  Full-screen detail using the `Listing` payload (no extra API call per technical brief).
//  Localized labels only; title/description body text follows API language.
//

import SwiftUI

private struct PresentedListingPhoto: Identifiable {
    let id = UUID()
    let url: URL
}

struct ListingDetailView: View {
    let listing: Listing
    let categoryName: String
    let configuration: APIConfiguration

    @Environment(\.locale) private var locale

    @State private var presentedPhoto: PresentedListingPhoto?

    private let heroCornerRadius: CGFloat = 20

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero: width bounded by ScrollView; image cannot force intrinsic width past screen.
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let url = preferredImageURL() {
                            presentedPhoto = PresentedListingPhoto(url: url)
                        }
                    }
                    .accessibilityAddTraits(preferredImageURL() != nil ? .isButton : [])
                    .accessibilityHint("accessibility_photo_open_fullscreen")

                VStack(alignment: .leading, spacing: 16) {
                    // `minWidth: 0` lets the row compress so HStack + ScrollView don’t expand past the screen (classic wrap bug).
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(PriceFormatting.string(for: listing.price, locale: locale))
                            .font(AppTypography.priceLarge())
                            .foregroundStyle(Color.appPrice)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.leading)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                        if listing.isUrgent {
                            Text("urgent_badge")
                                .font(AppTypography.captionStrong())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.appBrand)
                                .clipShape(Capsule())
                                .fixedSize()
                                .accessibilityLabel(Text("accessibility_urgent_listing"))
                        }
                    }

                    Text(listing.title)
                        .font(AppTypography.title3())
                        .foregroundStyle(Color.appNavy)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
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
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Text(listing.description)
                        .font(AppTypography.body())
                        .foregroundStyle(Color.appNavy.opacity(0.9))
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous))
                .padding(.horizontal, 16)
                // Prefer negative top padding over `offset`: avoids ScrollView + clipShape drawing glitches on some OS versions.
                .padding(.top, -28)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 24)
        }
        .background(AppScreenBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .font(AppTypography.body())
        .fullScreenCover(item: $presentedPhoto) { item in
            ListingImageFullScreenView(url: item.url, onClose: { presentedPhoto = nil })
        }
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Text(value)
                    .font(AppTypography.subheadline(weight: .semibold))
                    .foregroundStyle(Color.appNavy)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
