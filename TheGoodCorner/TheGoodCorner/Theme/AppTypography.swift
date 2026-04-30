//
//  AppTypography.swift
//  TheGoodCorner
//
//  Plus Jakarta Sans is bundled as static TTF files (SIL Open Font License).
//  Custom fonts are allowed by the brief (no third-party Swift packages).
//

import SwiftUI

enum AppTypography {
    /// Large navigation title uses Bold.
    static func largeTitle() -> Font {
        .custom("PlusJakartaSans-Bold", size: 34, relativeTo: .largeTitle)
    }

    static func title3() -> Font {
        .custom("PlusJakartaSans-Bold", size: 22, relativeTo: .title3)
    }

    static func headline() -> Font {
        .custom("PlusJakartaSans-SemiBold", size: 17, relativeTo: .headline)
    }

    static func body() -> Font {
        .custom("PlusJakartaSans-Regular", size: 17, relativeTo: .body)
    }

    static func subheadline(weight: FontWeight = .regular) -> Font {
        switch weight {
        case .regular:
            return .custom("PlusJakartaSans-Regular", size: 15, relativeTo: .subheadline)
        case .semibold:
            return .custom("PlusJakartaSans-SemiBold", size: 15, relativeTo: .subheadline)
        }
    }

    static func caption() -> Font {
        .custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption)
    }

    static func captionStrong() -> Font {
        .custom("PlusJakartaSans-SemiBold", size: 12, relativeTo: .caption)
    }

    /// Price on the detail hero (larger than body).
    static func priceLarge() -> Font {
        .custom("PlusJakartaSans-Bold", size: 28, relativeTo: .title2)
    }

    enum FontWeight {
        case regular
        case semibold
    }
}

/// Applies Jakarta across common controls while respecting Dynamic Type (`relativeTo:`).
struct AppFontEnvironment: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTypography.body())
    }
}

extension View {
    func appScreenFonts() -> some View {
        modifier(AppFontEnvironment())
    }
}
