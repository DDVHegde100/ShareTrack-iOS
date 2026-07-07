import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: String
    var username: String
    var inviteCode: String
    var connectedPlatforms: [PlatformConnection]
    var friendID: String?
    var friendUsername: String?
    var totalPoints: Int
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        username: String,
        inviteCode: String = UserProfile.generateInviteCode(),
        connectedPlatforms: [PlatformConnection] = [],
        friendID: String? = nil,
        friendUsername: String? = nil,
        totalPoints: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.inviteCode = inviteCode
        self.connectedPlatforms = connectedPlatforms
        self.friendID = friendID
        self.friendUsername = friendUsername
        self.totalPoints = totalPoints
        self.createdAt = createdAt
    }

    static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    func connection(for platform: SocialPlatform) -> PlatformConnection? {
        connectedPlatforms.first { $0.platform == platform }
    }

    var hasFriend: Bool { friendID != nil }
}

struct PlatformConnection: Codable, Identifiable, Equatable {
    var id: String { platform.rawValue }
    let platform: SocialPlatform
    var handle: String
    var externalID: String?
    var connectedAt: Date
    var isVerified: Bool

    init(
        platform: SocialPlatform,
        handle: String,
        externalID: String? = nil,
        connectedAt: Date = Date(),
        isVerified: Bool = false
    ) {
        self.platform = platform
        self.handle = handle
        self.externalID = externalID
        self.connectedAt = connectedAt
        self.isVerified = isVerified
    }
}
