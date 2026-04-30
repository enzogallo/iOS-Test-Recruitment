//
//  APIConfiguration.swift
//  TheGoodCorner
//
//  Central place for the API base URL. The app can swap the URL for a physical device
//  (LAN IP) while the simulator uses loopback to the host running the local server.
//

import Foundation

/// Server root for all HTTP JSON calls and for turning feed image paths into absolute URLs.
struct APIConfiguration: Sendable {
    /// Root URL with scheme, host, and port only—no path suffix (e.g. `http://127.0.0.1:8080`).
    let baseURL: URL

    /// Points at the machine running `swift run` in `server/`; works from the iOS Simulator because it shares the Mac network stack.
    static let defaultSimulator = APIConfiguration(
        baseURL: URL(string: "http://127.0.0.1:8080")!
    )

    /// Combines `baseURL` with a path returned by the API (`/images/...`).
    /// Accepts already-absolute URLs so callers can pass through either form safely.
    func absoluteURL(forServerRelativePath path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: trimmed, relativeTo: baseURL)?.absoluteURL
    }
}
