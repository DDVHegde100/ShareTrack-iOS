import Foundation

struct CategoryStat: Codable, Identifiable, Equatable {
    var id: String { category.rawValue }
    let category: ContentCategory
    var count: Int
    var averageRating: Double
}

struct RelationshipMetrics: Codable, Equatable {
    var relationshipScore: Int
    var averageRating: Double
    var totalRated: Int
    var categoryStats: [CategoryStat]
    var sentCount: Int
    var receivedCount: Int
    var balanceScore: Int
    var weeklyShares: Int
    var monthlyShares: Int
    var topCategory: ContentCategory?
    var ratingDistribution: [Int: Int]

    static var empty: RelationshipMetrics {
        RelationshipMetrics(
            relationshipScore: 0,
            averageRating: 0,
            totalRated: 0,
            categoryStats: ContentCategory.allCases.map {
                CategoryStat(category: $0, count: 0, averageRating: 0)
            },
            sentCount: 0,
            receivedCount: 0,
            balanceScore: 50,
            weeklyShares: 0,
            monthlyShares: 0,
            topCategory: nil,
            ratingDistribution: [:]
        )
    }

    var scoreLabel: String {
        switch relationshipScore {
        case 0..<20: return "Getting Started"
        case 20..<40: return "Warming Up"
        case 40..<60: return "In Sync"
        case 60..<80: return "Strong Bond"
        case 80..<95: return "Power Couple"
        default: return "Soulmates"
        }
    }
}

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var unlockedAt: Date?

    static func catalog(unlockedIDs: Set<String>, unlockDates: [String: Date]) -> [Achievement] {
        let all: [(String, String, String, String)] = [
            ("first_share", "First Share", "Log your first video", "paperplane.fill"),
            ("ten_shares", "Getting Started", "Share 10 videos total", "star.fill"),
            ("fifty_shares", "Content Couple", "Share 50 videos total", "heart.fill"),
            ("hundred_shares", "Share Masters", "Share 100 videos total", "crown.fill"),
            ("week_streak", "Week Streak", "7-day sharing streak", "flame.fill"),
            ("month_streak", "Monthly Streak", "30-day sharing streak", "bolt.fill"),
            ("all_caught_up", "All Caught Up", "Zero unviewed videos", "eye.fill"),
            ("five_star", "Five Star Friend", "Rate 10 videos 5 stars", "star.circle.fill"),
            ("category_explorer", "Category Explorer", "Use 5+ categories", "tag.fill"),
            ("chatterbox", "Chatterbox", "Send 25 chat messages", "bubble.left.fill"),
            ("balanced", "Perfect Balance", "50/50 send/receive ratio", "scalemass.fill"),
            ("soulmate_score", "Soulmate Score", "Relationship score 90+", "heart.text.square.fill")
        ]
        return all.map { id, title, desc, icon in
            Achievement(
                id: id,
                title: title,
                description: desc,
                icon: icon,
                isUnlocked: unlockedIDs.contains(id),
                unlockedAt: unlockDates[id]
            )
        }
    }
}
