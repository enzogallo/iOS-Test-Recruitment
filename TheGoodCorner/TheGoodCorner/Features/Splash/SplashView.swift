//
//  SplashView.swift
//  TheGoodCorner
//
//  Cold-launch overlay: same chrome as the list (`AppScreenBackground`) plus a short intro animation.
//

import SwiftUI

struct SplashView: View {
    @State private var titleShown = false

    var body: some View {
        ZStack {
            AppScreenBackground()

            VStack(spacing: 14) {
                Image("applogofeed")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 56)
                    .accessibilityLabel(Text("app_title"))
                    .opacity(titleShown ? 1 : 0)
                    .scaleEffect(titleShown ? 1 : 0.9, anchor: .center)
                    .blur(radius: titleShown ? 0 : 2)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.76)) {
                titleShown = true
            }
        }
    }
}

#Preview {
    SplashView()
}
