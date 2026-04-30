//
//  LiquidGlassCompat.swift
//  TheGoodCorner
//
//  iOS 26+: Liquid Glass (`.glassEffect`) on chrome surfaces where it aids hierarchy.
//  iOS 16–25: Falls back to ultra-thin material (same structural layout).
//
//  Compile requires an Xcode / SDK that declares `glassEffect` when building with iOS 26 SDK.
//

import SwiftUI

extension View {
    /// Decorative chrome for **message panels** (empty search, empty error, load failure) — not on dense lists or tiny chips
    /// (filters stay solid: glass behind opaque pills would not read).
    @ViewBuilder
    func appLiquidChromeCard(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26.0, *) {
            self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

@available(iOS 26.0, *)
private struct LiquidGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
