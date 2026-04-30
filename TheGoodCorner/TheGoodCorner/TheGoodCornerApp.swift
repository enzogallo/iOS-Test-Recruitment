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
    @State private var showSplash = true

    init() {
        NavigationBarAppearanceConfigurator.applyJakartaNavigationFonts()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ListingListView()

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                        .task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            await MainActor.run {
                                withAnimation(.easeOut(duration: 0.35)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
    }
}
