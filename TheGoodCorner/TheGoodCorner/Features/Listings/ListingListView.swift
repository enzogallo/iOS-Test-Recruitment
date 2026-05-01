//
//  ListingListView.swift
//  TheGoodCorner
//
//  Main feed: multi-select category chips, per-category rails (3-card preview, expandable grid),
//  single-filter auto-expand. Localized via `L10n` + `fr.lproj` / `en.lproj`.
//

import SwiftUI

struct ListingListView: View {
    @StateObject private var viewModel = ListingListViewModel()
    @Environment(\.locale) private var locale

    /// Fixed card width inside horizontal rails (grid flexibility is handled by the outer `ScrollView`).
    private let railCardWidth: CGFloat = 172

    /// Collapsed rail shows at most this many cards; “Voir plus” appears only when there are more.
    private let railPreviewItemCount = 3

    private let expandedGridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    /// Rails toggled to a vertical grid via “Voir plus”.
    @State private var expandedRailIds: Set<Int> = []

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackground()

                mainContent
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            // In-content search under the logo header (pinned while scrolling).
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.searchText) { _ in
                viewModel.searchTextDidChange()
            }
            .onChange(of: viewModel.selectedCategoryIds) { newIds in
                syncExpandedRailsWithFilterSelection(newIds)
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
                LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                    Section(header: pinnedHeader) {
                        let allRails = viewModel.categoryRailSections(locale: locale)
                        let rails = viewModel.visibleCategoryRailSections(locale: locale)
                        if allRails.isEmpty {
                            if viewModel.trimmedSearchQuery != nil {
                                searchEmptyState
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 200)
                            } else {
                                feedEmptyState
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 200)
                            }
                        } else if rails.isEmpty {
                            filterEmptyState
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 200)
                        } else {
                            ForEach(rails) { section in
                                categoryRail(section: section)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    /// Single selected category with more than `railPreviewItemCount` listings → expand; any other case → collapsed.
    private func syncExpandedRailsWithFilterSelection(_ ids: Set<Int>) {
        guard ids.count == 1, let onlyId = ids.first,
              let section = viewModel.categoryRailSections(locale: locale).first(where: { $0.id == onlyId }),
              section.listings.count > railPreviewItemCount
        else {
            expandedRailIds = []
            return
        }
        expandedRailIds = [onlyId]
    }

    private func categoryRail(section: CategoryRailSection) -> some View {
        let isExpanded = expandedRailIds.contains(section.id)
        let previewListings = Array(section.listings.prefix(railPreviewItemCount))
        let showsExpandControl = section.listings.count > railPreviewItemCount

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(section.title)
                        .font(AppTypography.headline())
                        .foregroundStyle(Color.appNavy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text("\(section.listings.count)")
                        .font(AppTypography.caption())
                        .foregroundStyle(Color.appSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    L10n.format("accessibility_category_rail", locale: locale, section.title, count: section.listings.count)
                )

                if showsExpandControl {
                    Button {
                        if isExpanded {
                            expandedRailIds.remove(section.id)
                        } else {
                            expandedRailIds.insert(section.id)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isExpanded ? L10n.string("action_see_less", locale: locale) : L10n.string("action_see_more", locale: locale))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .baselineOffset(-1)
                        }
                        .font(AppTypography.caption())
                        .foregroundStyle(Color.appSecondaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        isExpanded
                            ? L10n.format("accessibility_see_less_rail", locale: locale, section.title)
                            : L10n.format("accessibility_see_more_rail", locale: locale, section.title)
                    )
                }
            }

            if isExpanded {
                LazyVGrid(columns: expandedGridColumns, alignment: .center, spacing: 12) {
                    ForEach(section.listings) { listing in
                        listingNavigationLink(for: listing, grid: true)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(previewListings) { listing in
                            listingNavigationLink(for: listing, grid: false)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func listingNavigationLink(for listing: Listing, grid: Bool) -> some View {
        NavigationLink(value: listing) {
            let card = ListingCardView(
                listing: listing,
                categoryName: viewModel.categoryDisplayName(for: listing, locale: locale),
                imageURL: thumbnailURL(for: listing)
            )
            if grid {
                card.frame(maxWidth: .infinity, alignment: .top)
            } else {
                card.frame(width: railCardWidth, alignment: .top)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack {
            Spacer(minLength: 0)
            Image("applogofeed")
                .resizable()
                .scaledToFit()
                .frame(height: 44)
                .accessibilityLabel(Text("app_title"))
            Spacer(minLength: 0)
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.appSecondaryText)

            TextField(L10n.string("search_prompt", locale: locale), text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.appSecondaryText.opacity(0.85))
                }
                .accessibilityLabel(Text("action_clear_search"))
            }
        }
        .font(AppTypography.body())
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("search_prompt"))
    }

    /// Sticky header: keeps branding + search visible while scrolling.
    private var pinnedHeader: some View {
        VStack(spacing: 10) {
            header
            // Extra lateral inset so the search field doesn't touch the glass edge.
            searchField
                .padding(.horizontal, 8)
            if !viewModel.categoryRailSections(locale: locale).isEmpty {
                categoryFilterRow
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
        // More "glass" than a plain material: iOS 26 uses `glassEffect`, iOS 16–25 falls back to ultra-thin material.
        .appLiquidChromeCard(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(titleKey: "filter_all", categoryId: nil, isAllChip: true)
                ForEach(viewModel.categoryRailSections(locale: locale)) { section in
                    categoryChip(title: section.title, categoryId: section.id, isAllChip: false)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 12)
        .accessibilityLabel(Text("accessibility_category_filters"))
    }

    private func categoryChip(titleKey: String, categoryId: Int?, isAllChip: Bool) -> some View {
        categoryChip(title: L10n.string(titleKey, locale: locale), categoryId: categoryId, isAllChip: isAllChip)
    }

    private func categoryChip(title: String, categoryId: Int?, isAllChip: Bool) -> some View {
        let selected: Bool = {
            if isAllChip { return viewModel.selectedCategoryIds.isEmpty }
            guard let categoryId else { return false }
            return viewModel.selectedCategoryIds.contains(categoryId)
        }()

        return Button {
            if isAllChip {
                viewModel.clearCategoryFilters()
            } else if let categoryId {
                viewModel.toggleCategoryFilter(categoryId)
            }
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

    private var filterEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 36))
                .foregroundStyle(Color.appSecondaryText)
            Text("empty_filter_title")
                .font(AppTypography.headline())
                .foregroundStyle(Color.appNavy)
            Text("empty_filter_subtitle")
                .font(AppTypography.subheadline(weight: .regular))
                .foregroundStyle(Color.appSecondaryText)
                .multilineTextAlignment(.center)
            Button("action_clear_filters") {
                viewModel.clearCategoryFilters()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appBrand)
            .font(AppTypography.headline())
        }
        .padding(24)
        .appLiquidChromeCard(cornerRadius: 16)
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

    private var feedEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(Color.appSecondaryText)
            Text("empty_feed_title")
                .font(AppTypography.headline())
                .foregroundStyle(Color.appNavy)
            Text("empty_feed_subtitle")
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
