import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var screen: AppScreen = .launcher
    @Published var backendText: String = UserDefaults.standard.string(forKey: "mobileAppBackendUrl") ?? ""
    @Published var codeText: String = ""
    @Published var statusText: String = "Ready"

    private let tokenStore = TokenStore()
    private var config: MobileAppConfig?

    // Intentionally blank in the reconstructed source. If your backend requires its own
    // Authorization header, configure a NEW credential here or move it to server-side config.
    private var backendAuthorizationHeader: String? { nil }

    func handleDeepLink(_ url: URL) async {
        guard url.scheme?.lowercased() == "rdapp" else { return }
        let parts = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = parts?.queryItems ?? []
        let backend = items.first(where: { $0.name == "backend" })?.value
        let code = items.first(where: { $0.name == "code" })?.value
        if let backend { backendText = backend }
        if let code { codeText = code }
        await connect()
    }

    func connect() async {
        guard let base = normalizedBackendURL(backendText) else {
            screen = .error("Invalid backend URL")
            return
        }
        UserDefaults.standard.set(base.absoluteString, forKey: "mobileAppBackendUrl")
        screen = .connecting
        statusText = "Loading configuration…"

        let client = BackendClient(baseURL: base, authorizationHeader: backendAuthorizationHeader)
        do {
            let cfg = try await client.config()
            config = cfg
            if cfg.maintenance {
                screen = .maintenance(cfg.maintenanceReason ?? "Maintenance in progress")
                return
            }

            if !codeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                statusText = "Authenticating…"
                let tokens = try await client.exchange(code: codeText.trimmingCharacters(in: .whitespacesAndNewlines))
                try tokenStore.save(tokens)
                codeText = ""
            } else if let tokens = tokenStore.load(), let refresh = tokens.refreshToken {
                do {
                    let newTokens = try await client.refresh(refreshToken: refresh)
                    try tokenStore.save(newTokens)
                } catch {
                    // Existing access token may still be usable; continue to the web app.
                }
            }

            guard let webURL = URL(string: cfg.webAppRootUrl) else {
                throw URLError(.badURL)
            }
            statusText = "Connected"
            screen = .web(webURL)
        } catch {
            statusText = "Connection failed"
            screen = .error(error.localizedDescription)
        }
    }

    func logout() {
        tokenStore.clear()
        screen = .launcher
        statusText = "Logged out"
    }

    func tokensForWebView() -> TokenEnvelope? { tokenStore.load() }

    func redeemURL() -> URL? {
        guard let raw = config?.webAppRedeemUrl else { return nil }
        return URL(string: raw)
    }

    private func normalizedBackendURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        return URL(string: candidate)
    }
}
