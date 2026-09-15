import Foundation

struct MobileAppConfig: Codable, Equatable {
    let androidLatestAppVersionBuild: Int?
    let iosLatestAppVersionBuild: Int?
    let androidUpdateUrl: String?
    let iosUpdateUrl: String?
    let webAppRootUrl: String
    let webAppRedeemUrl: String?
    let maintenance: Bool
    let maintenanceReason: String?
}

struct AuthExchangeRequest: Codable { let code: String }
struct RefreshRequest: Codable { let refreshToken: String }

struct TokenEnvelope: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, expiresIn
        case accessTokenSnake = "access_token"
        case refreshTokenSnake = "refresh_token"
        case expiresInSnake = "expires_in"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try c.decodeIfPresent(String.self, forKey: .accessToken)
            ?? c.decode(String.self, forKey: .accessTokenSnake)
        refreshToken = try c.decodeIfPresent(String.self, forKey: .refreshToken)
            ?? c.decodeIfPresent(String.self, forKey: .refreshTokenSnake)
        expiresIn = try c.decodeIfPresent(Int.self, forKey: .expiresIn)
            ?? c.decodeIfPresent(Int.self, forKey: .expiresInSnake)
    }

    init(accessToken: String, refreshToken: String?, expiresIn: Int?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(accessToken, forKey: .accessToken)
        try c.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try c.encodeIfPresent(expiresIn, forKey: .expiresIn)
    }
}

enum AppScreen: Equatable {
    case launcher
    case connecting
    case maintenance(String)
    case web(URL)
    case error(String)
}
