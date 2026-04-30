//
//  AppScreenBackground.swift
//  TheGoodCorner
//
//  Screen chrome: `SurfaceBackground` plus a very soft diagonal wash using semantic
//  brand colors (`BrandOrange`, `NavyPrimary`) — marketplace-style warmth without loud tint.
//

import SwiftUI

/// Full-screen backdrop for list and detail — subtle orange→navy gradient over the base surface.
struct AppScreenBackground: View {
    var body: some View {
        ZStack {
            Color.appSurface

            // Warm corner — brand orange, slightly stronger than before but still background-level.
            LinearGradient(
                colors: [
                    Color.appBrand.opacity(0.16),
                    Color.appBrand.opacity(0.05),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.55, y: 0.45)
            )

            // Cool finish toward the bottom — balances the orange and matches the nav / text navy.
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.appNavy.opacity(0.11),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.35),
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}
