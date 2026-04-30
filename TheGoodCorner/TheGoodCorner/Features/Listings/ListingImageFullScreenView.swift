//
//  ListingImageFullScreenView.swift
//  TheGoodCorner
//
//  Full-screen photo viewer (tap hero on detail). Pinch to zoom, button to close.
//

import SwiftUI

struct ListingImageFullScreenView: View {
    let url: URL
    let onClose: () -> Void

    @State private var anchorScale: CGFloat = 1
    /// Magnification relative to the current pinch gesture (starts at 1).
    @State private var pinchMagnification: CGFloat = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(anchorScale * pinchMagnification)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .gesture(magnificationGesture)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.5))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_close_photo", action: onClose)
                        .font(AppTypography.headline())
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.35), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                pinchMagnification = value
            }
            .onEnded { _ in
                var next = anchorScale * pinchMagnification
                pinchMagnification = 1
                next = min(max(next, 1), 5)
                anchorScale = next
            }
    }
}
