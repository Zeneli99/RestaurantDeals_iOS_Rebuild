import SwiftUI
import WebKit

struct WebContainer: UIViewRepresentable {
    let url: URL
    let tokens: TokenEnvelope?
    let onBridgeEvent: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onBridgeEvent: onBridgeEvent) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "AvensBridge")

        if let tokens,
           let json = try? JSONEncoder().encode(tokens),
           let string = String(data: json, encoding: .utf8) {
            let escaped = string
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let js = "sessionStorage.setItem('mobileAppAuth', '\(escaped)');"
            controller.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }

        config.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let onBridgeEvent: (String) -> Void
        init(onBridgeEvent: @escaping (String) -> Void) { self.onBridgeEvent = onBridgeEvent }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // The Android build exposes an AvensBridge with proxy controls. This iOS rebuild
            // deliberately does NOT emulate/fake Android Play Integrity or tunnel protected
            // third-party traffic. We surface the request so an authorized iOS integration
            // can be implemented against the backend/API you control.
            if let text = message.body as? String {
                onBridgeEvent(text)
            } else if let data = try? JSONSerialization.data(withJSONObject: message.body),
                      let text = String(data: data, encoding: .utf8) {
                onBridgeEvent(text)
            } else {
                onBridgeEvent(String(describing: message.body))
            }
        }
    }
}
