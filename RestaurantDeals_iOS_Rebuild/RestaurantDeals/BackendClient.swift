import Foundation

struct BackendClient {
    let baseURL: URL
    var authorizationHeader: String? = nil

    private func request(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { req.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if let authorizationHeader, !authorizationHeader.isEmpty {
            req.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body
        return req
    }

    private func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "RestaurantDeals.Backend", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode) \(body)"])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func config() async throws -> MobileAppConfig {
        try await perform(request(path: "/api/mobile-app/config"), as: MobileAppConfig.self)
    }

    func exchange(code: String) async throws -> TokenEnvelope {
        let body = try JSONEncoder().encode(AuthExchangeRequest(code: code))
        return try await perform(request(path: "/api/mobile-app/auth/exchange", method: "POST", body: body), as: TokenEnvelope.self)
    }

    func refresh(refreshToken: String) async throws -> TokenEnvelope {
        let body = try JSONEncoder().encode(RefreshRequest(refreshToken: refreshToken))
        return try await perform(request(path: "/api/mobile-app/auth/token", method: "POST", body: body), as: TokenEnvelope.self)
    }
}
