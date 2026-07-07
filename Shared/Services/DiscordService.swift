import Foundation
import AuthenticationServices

@MainActor
final class DiscordService: ObservableObject {
    static let shared = DiscordService()

    @Published var isConnecting = false
    @Published var connectionError: String?

    private init() {}

    var authURL: URL? {
        guard AppConstants.discordClientID != "YOUR_DISCORD_CLIENT_ID" else { return nil }
        var components = URLComponents(string: "https://discord.com/api/oauth2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: AppConstants.discordClientID),
            URLQueryItem(name: "redirect_uri", value: AppConstants.discordRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "identify")
        ]
        return components.url
    }

    func handleCallback(url: URL) async -> PlatformConnection? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            connectionError = "Failed to get authorization code"
            return nil
        }

        isConnecting = true
        defer { isConnecting = false }

        do {
            let token = try await exchangeCodeForToken(code: code)
            let user = try await fetchDiscordUser(token: token)
            return PlatformConnection(
                platform: .discord,
                handle: user.username,
                externalID: user.id,
                isVerified: true
            )
        } catch {
            connectionError = error.localizedDescription
            return nil
        }
    }

    private struct DiscordTokenResponse: Decodable {
        let access_token: String
    }

    private struct DiscordUser: Decodable {
        let id: String
        let username: String
        let global_name: String?
    }

    private func exchangeCodeForToken(code: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://discord.com/api/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id": AppConstants.discordClientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": AppConstants.discordRedirectURI
        ]
        request.httpBody = body.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let tokenResponse = try JSONDecoder().decode(DiscordTokenResponse.self, from: data)
        return tokenResponse.access_token
    }

    private func fetchDiscordUser(token: String) async throws -> DiscordUser {
        var request = URLRequest(url: URL(string: "https://discord.com/api/users/@me")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(DiscordUser.self, from: data)
    }
}

enum PlatformConnectionHelper {
    static func validateHandle(_ handle: String, for platform: SocialPlatform) -> String? {
        let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Handle cannot be empty" }

        switch platform {
        case .instagram, .tiktok:
            let pattern = "^@?[a-zA-Z0-9._]{1,30}$"
            guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
                return "Invalid username format"
            }
        case .discord:
            let pattern = "^.{2,32}$"
            guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
                return "Invalid Discord username"
            }
        case .snapchat:
            let pattern = "^@?[a-zA-Z0-9._-]{3,15}$"
            guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
                return "Invalid Snapchat username"
            }
        case .youtube:
            if !trimmed.hasPrefix("@") && !trimmed.hasPrefix("UC") {
                return "Use @handle or channel ID"
            }
        }
        return nil
    }

    static func normalizeHandle(_ handle: String) -> String {
        var h = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("@") { h = String(h.dropFirst()) }
        return h
    }
}
