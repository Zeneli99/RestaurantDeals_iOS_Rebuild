import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            switch model.screen {
            case .launcher:
                launcher
            case .connecting:
                ProgressView(model.statusText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .maintenance(let reason):
                messageView(title: "Maintenance", message: reason)
            case .error(let message):
                messageView(title: "Connection error", message: message)
            case .web(let url):
                webView(url)
            }
        }
    }

    private var launcher: some View {
        NavigationStack {
            Form {
                Section("Restaurant Deals") {
                    TextField("Backend URL", text: $model.backendText)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    TextField("Login code", text: $model.codeText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    Button("Connect") { Task { await model.connect() } }
                        .frame(maxWidth: .infinity)
                }
                Section {
                    Text("You can also open an rdapp:// login link containing backend and code parameters.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Restaurant Deals")
        }
    }

    private func webView(_ url: URL) -> some View {
        VStack(spacing: 0) {
            WebContainer(url: url, tokens: model.tokensForWebView()) { event in
                model.statusText = "Bridge: \(event.prefix(100))"
            }
            Divider()
            HStack {
                Text(model.statusText).lineLimit(1).font(.caption)
                Spacer()
                if let redeem = model.redeemURL() {
                    Link("Redeem", destination: redeem)
                }
                Button("Logout") { model.logout() }
            }
            .padding(10)
        }
    }

    private func messageView(title: String, message: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Back") { model.screen = .launcher }
        }
    }
}
