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
    var category: ContentCategory
    var rating: Int?
    var reaction: ShareReaction?
    var note: String?

    enum CodingKeys: String, CodingKey {
        case id, senderID, receiverID, platform, sharedAt, isViewed
        case contentURL, pointsEarned, category, rating, reaction, note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        senderID = try c.decode(String.self, forKey: .senderID)
        receiverID = try c.decode(String.self, forKey: .receiverID)
        platform = try c.decode(SocialPlatform.self, forKey: .platform)
        sharedAt = try c.decode(Date.self, forKey: .sharedAt)
        isViewed = try c.decode(Bool.self, forKey: .isViewed)
        contentURL = try c.decodeIfPresent(String.self, forKey: .contentURL)
        pointsEarned = try c.decodeIfPresent(Int.self, forKey: .pointsEarned) ?? platform.pointsPerShare
        category = try c.decodeIfPresent(ContentCategory.self, forKey: .category) ?? .other
        rating = try c.decodeIfPresent(Int.self, forKey: .rating)
        reaction = try c.decodeIfPresent(ShareReaction.self, forKey: .reaction)
        note = try c.decodeIfPresent(String.self, forKey: .note)
    }

    init(
        id: String = UUID().uuidString,
        senderID: String,
        receiverID: String,
        platform: SocialPlatform,
        sharedAt: Date = Date(),
        isViewed: Bool = false,
        contentURL: String? = nil,
        pointsEarned: Int? = nil,
        category: ContentCategory = .other,
        rating: Int? = nil,
        reaction: ShareReaction? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.platform = platform
        self.sharedAt = sharedAt
        self.isViewed = isViewed
        self.contentURL = contentURL
        self.category = category
        self.rating = rating
        self.reaction = reaction
        self.note = note

        let base = platform.pointsPerShare + category.bonusPoints
        self.pointsEarned = pointsEarned ?? base
    }

    var hasRating: Bool { rating != nil }
}

struct PlatformStats: Codable, Identifiable, Equatable {
    var id: String { platform.rawValue }
    let platform: SocialPlatform
    var totalSent: Int
    var totalReceived: Int
    var unviewedCount: Int
    var dailyCounts: [DailyCount]
    var pointsEarned: Int
    var averageRating: Double

    enum CodingKeys: String, CodingKey {
        case platform, totalSent, totalReceived, unviewedCount, dailyCounts, pointsEarned, averageRating
    }

    init(platform: SocialPlatform, totalSent: Int, totalReceived: Int, unviewedCount: Int, dailyCounts: [DailyCount], pointsEarned: Int, averageRating: Double) {
        self.platform = platform
        self.totalSent = totalSent
        self.totalReceived = totalReceived
        self.unviewedCount = unviewedCount
        self.dailyCounts = dailyCounts
        self.pointsEarned = pointsEarned
        self.averageRating = averageRating
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        platform = try c.decode(SocialPlatform.self, forKey: .platform)
        totalSent = try c.decode(Int.self, forKey: .totalSent)
        totalReceived = try c.decode(Int.self, forKey: .totalReceived)
        unviewedCount = try c.decode(Int.self, forKey: .unviewedCount)
        dailyCounts = try c.decode([DailyCount].self, forKey: .dailyCounts)
        pointsEarned = try c.decode(Int.self, forKey: .pointsEarned)
        averageRating = try c.decodeIfPresent(Double.self, forKey: .averageRating) ?? 0
    }

    var totalExchanged: Int { totalSent + totalReceived }

    static func empty(for platform: SocialPlatform) -> PlatformStats {
        PlatformStats(
            platform: platform,
            totalSent: 0,
            totalReceived: 0,
            unviewedCount: 0,
            dailyCounts: [],
            pointsEarned: 0,
            averageRating: 0
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
    var relationshipMetrics: RelationshipMetrics

    enum CodingKeys: String, CodingKey {
        case platformStats, totalPoints, streakDays, lastUpdated, relationshipMetrics
    }

    init(platformStats: [PlatformStats], totalPoints: Int, streakDays: Int, lastUpdated: Date, relationshipMetrics: RelationshipMetrics) {
        self.platformStats = platformStats
        self.totalPoints = totalPoints
        self.streakDays = streakDays
        self.lastUpdated = lastUpdated
        self.relationshipMetrics = relationshipMetrics
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        platformStats = try c.decode([PlatformStats].self, forKey: .platformStats)
        totalPoints = try c.decode(Int.self, forKey: .totalPoints)
        streakDays = try c.decode(Int.self, forKey: .streakDays)
        lastUpdated = try c.decode(Date.self, forKey: .lastUpdated)
        relationshipMetrics = try c.decodeIfPresent(RelationshipMetrics.self, forKey: .relationshipMetrics) ?? .empty
    }

    static var empty: AppStats {
        AppStats(
            platformStats: SocialPlatform.allCases.map { PlatformStats.empty(for: $0) },
            totalPoints: 0,
            streakDays: 0,
            lastUpdated: Date(),
            relationshipMetrics: .empty
        )
    }

    func stats(for platform: SocialPlatform) -> PlatformStats {
        platformStats.first { $0.platform == platform } ?? PlatformStats.empty(for: platform)
    }
}
