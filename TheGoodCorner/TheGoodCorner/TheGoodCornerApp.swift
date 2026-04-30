//
//  TheGoodCornerApp.swift
//  TheGoodCorner
//
//  Entry point: registers Jakarta navigation fonts once. UI language follows the system
//  (Settings → The Good Corner → Language). Listing/API text still comes from the server.
//

import SwiftUI

@main
struct TheGoodCornerApp: App {
    init() {
        NavigationBarAppearanceConfigurator.applyJakartaNavigationFonts()
    }

    var body: some Scene {
        WindowGroup {
            ListingListView()
        }
    }
}
