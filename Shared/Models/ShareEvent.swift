import Foundation

struct ShareEvent: Codable, Identifiable, Equatable {
    let id: String
    let senderID: String
    let receiverID: String
    let platform: SocialPlatform
    let sharedAt: Date
    var isViewed: Bool
    var contentURL: String?
    var pointsEarned: Int

    init(
        id: String = UUID().uuidString,
        senderID: String,
        receiverID: String,
        platform: SocialPlatform,
        sharedAt: Date = Date(),
        isViewed: Bool = false,
        contentURL: String? = nil,
        pointsEarned: Int? = nil
    ) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.platform = platform
        self.sharedAt = sharedAt
        self.isViewed = isViewed
        self.contentURL = contentURL
        self.pointsEarned = pointsEarned ?? platform.pointsPerShare
    }
}

struct PlatformStats: Codable, Identifiable, Equatable {
    var id: String { platform.rawValue }
    let platform: SocialPlatform
    var totalSent: Int
    var totalReceived: Int
    var unviewedCount: Int
    var dailyCounts: [DailyCount]
    var pointsEarned: Int

    var totalExchanged: Int { totalSent + totalReceived }

    static func empty(for platform: SocialPlatform) -> PlatformStats {
        PlatformStats(
            platform: platform,
            totalSent: 0,
            totalReceived: 0,
            unviewedCount: 0,
            dailyCounts: [],
            pointsEarned: 0
        )
    }
}

struct DailyCount: Codable, Identifiable, Equatable {
    var id: String { dateKey }
    let date: Date
    var sent: Int
    var received: Int

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    var total: Int { sent + received }
}

struct AppStats: Codable, Equatable {
    var platformStats: [PlatformStats]
    var totalPoints: Int
    var streakDays: Int
    var lastUpdated: Date

    static var empty: AppStats {
        AppStats(
            platformStats: SocialPlatform.allCases.map { PlatformStats.empty(for: $0) },
            totalPoints: 0,
            streakDays: 0,
            lastUpdated: Date()
        )
    }

    func stats(for platform: SocialPlatform) -> PlatformStats {
        platformStats.first { $0.platform == platform } ?? PlatformStats.empty(for: platform)
    }
}
