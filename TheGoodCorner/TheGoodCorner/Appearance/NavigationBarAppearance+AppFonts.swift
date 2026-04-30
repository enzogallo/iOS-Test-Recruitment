//
//  NavigationBarAppearance+AppFonts.swift
//  TheGoodCorner
//
//  UIKit appearance hook so large titles and inline titles use Plus Jakarta Sans.
//  SwiftUI `.font` does not affect `navigationTitle`; UINavigationBarAppearance is required.
//

import SwiftUI
import UIKit

enum NavigationBarAppearanceConfigurator {
    /// Call once at launch (e.g. from `App.init`). Uses Dynamic Type via `UIFontMetrics`.
    static func applyJakartaNavigationFonts() {
        let largeBase = UIFont(name: "PlusJakartaSans-Bold", size: 34) ?? .systemFont(ofSize: 34, weight: .bold)
        let largeScaled = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: largeBase)

        let titleBase = UIFont(name: "PlusJakartaSans-SemiBold", size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        let titleScaled = UIFontMetrics(forTextStyle: .headline).scaledFont(for: titleBase)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.font: largeScaled]
        appearance.titleTextAttributes = [.font: titleScaled]

        let compact = UINavigationBarAppearance()
        compact.configureWithTransparentBackground()
        compact.titleTextAttributes = [.font: titleScaled]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = compact
        UINavigationBar.appearance().compactScrollEdgeAppearance = compact
    }
}
