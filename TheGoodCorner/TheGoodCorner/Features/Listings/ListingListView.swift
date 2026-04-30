//
//  ListingListView.swift
//  TheGoodCorner
//
//  Main feed: 2-column grid, category chips, debounced search (server `query`), pull-to-refresh.
//  Localized strings use the system language (`L10n` + `fr.lproj` / `en.lproj`).
//

import SwiftUI

struct ListingListView: View {
    @StateObject private var viewModel = ListingListViewModel()
    @Environment(\.locale) private var locale

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSurface.ignoresSafeArea()

                mainContent
            }
            .navigationTitle("app_title")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "search_prompt"
            )
            .onChange(of: viewModel.searchText) { _ in
                viewModel.searchTextDidChange()
            }
            .navigationDestination(for: Listing.self) { listing in
                ListingDetailView(
                    listing: listing,
                    categoryName: viewModel.categoryDisplayName(for: listing, locale: locale),
                    configuration: viewModel.configuration
                )
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
        .tint(Color.appBrand)
        .font(AppTypography.body())
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading && viewModel.listings.isEmpty {
            ProgressView("loading_listings")
                .font(AppTypography.subheadline(weight: .regular))
                .tint(Color.appBrand)
                .foregroundStyle(Color.appNavy)
        } else if let loadError = viewModel.loadError, viewModel.listings.isEmpty {
            errorEmptyState(error: loadError)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    categoryFilterRow

                    if viewModel.displayedListings.isEmpty {
                        searchEmptyState
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 200)
                    } else {
                        LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
                            ForEach(viewModel.displayedListings) { listing in
                                NavigationLink(value: listing) {
                                    ListingCardView(
                                        listing: listing,
                                        categoryName: viewModel.categoryDisplayName(for: listing, locale: locale),
                                        imageURL: thumbnailURL(for: listing)
                                    )
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, alignment: .top)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(titleKey: "filter_all", categoryId: nil)
                ForEach(viewModel.categories) { cat in
                    categoryChip(title: cat.name, categoryId: cat.id)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel(Text("accessibility_category_filters"))
    }

    private func categoryChip(titleKey: String, categoryId: Int?) -> some View {
        categoryChip(title: L10n.string(titleKey, locale: locale), categoryId: categoryId)
    }

    private func categoryChip(title: String, categoryId: Int?) -> some View {
        let selected = viewModel.selectedCategoryId == categoryId
        return Button {
            viewModel.selectedCategoryId = categoryId
        } label: {
            Text(title)
                .font(AppTypography.subheadline(weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Color.appNavy : Color.appSecondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color.appBrand.opacity(0.25) : Color.appChip)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selected ? Color.appBrand.opacity(0.6) : Color.clear, lineWidth: 1)
                )
        }
        .accessibilityLabel(L10n.format("accessibility_filter_by", locale: locale, title))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func thumbnailURL(for listing: Listing) -> URL? {
        let path = listing.imagesURL?.small ?? listing.imagesURL?.thumb
        guard let path else { return nil }
        return viewModel.configuration.absoluteURL(forServerRelativePath: path)
    }

    private func errorEmptyState(error: ListingLoadError) -> some View {
        let message = L10n.loadErrorMessage(for: error, locale: locale)
        return VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(Color.appBrand)
            Text("error_empty_title")
                .font(AppTypography.headline())
                .foregroundStyle(Color.appNavy)
            Text(message)
                .font(AppTypography.subheadline(weight: .regular))
                .foregroundStyle(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("action_retry") {
                Task { await viewModel.retry() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appBrand)
            .font(AppTypography.headline())
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .appLiquidChromeCard(cornerRadius: 16)
    }

    private var searchEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.appSecondaryText)
            Text("empty_search_title")
                .font(AppTypography.headline())
                .foregroundStyle(Color.appNavy)
            Text("empty_search_subtitle")
                .font(AppTypography.subheadline(weight: .regular))
                .foregroundStyle(Color.appSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .appLiquidChromeCard(cornerRadius: 16)
    }
}

#Preview {
    ListingListView()
}
