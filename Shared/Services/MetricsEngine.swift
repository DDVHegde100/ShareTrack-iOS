import Foundation

enum MetricsEngine {
    static func computeRelationshipMetrics(
        events: [ShareEvent],
        currentUserID: String,
        messageCount: Int
    ) -> RelationshipMetrics {
        let userEvents = events.filter { $0.senderID == currentUserID || $0.receiverID == currentUserID }
        guard !userEvents.isEmpty else { return .empty }

        let sent = userEvents.filter { $0.senderID == currentUserID }.count
        let received = userEvents.filter { $0.receiverID == currentUserID }.count
        let total = sent + received

        let rated = userEvents.compactMap(\.rating)
        let avgRating = rated.isEmpty ? 0 : Double(rated.reduce(0, +)) / Double(rated.count)

        var categoryMap: [ContentCategory: (count: Int, ratings: [Int])] = [:]
        for event in userEvents {
            var entry = categoryMap[event.category] ?? (0, [])
            entry.count += 1
            if let r = event.rating { entry.ratings.append(r) }
            categoryMap[event.category] = entry
        }

        let categoryStats = ContentCategory.allCases.map { cat in
            let data = categoryMap[cat] ?? (0, [])
            let avg = data.ratings.isEmpty ? 0 : Double(data.ratings.reduce(0, +)) / Double(data.ratings.count)
            return CategoryStat(category: cat, count: data.count, averageRating: avg)
        }

        let topStat = categoryStats.max(by: { $0.count < $1.count })
        let top = (topStat?.count ?? 0) > 0 ? topStat?.category : nil

        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let weekly = userEvents.filter { $0.sharedAt >= weekAgo }.count
        let monthly = userEvents.filter { $0.sharedAt >= monthAgo }.count

        var ratingDist: [Int: Int] = [:]
        for r in rated { ratingDist[r, default: 0] += 1 }

        let balance: Int
        if total == 0 {
            balance = 50
        } else {
            let ratio = Double(min(sent, received)) / Double(max(sent, received, 1))
            balance = Int(ratio * 100)
        }

        var score = 0
        score += min(total * 2, 40)
        score += min(Int(avgRating * 8), 24)
        score += min(balance / 5, 16)
        score += min(weekly * 2, 10)
        score += min(messageCount / 2, 10)
        if !categoryMap.isEmpty { score += min(categoryMap.keys.count * 2, 10) }
        score = min(score, 100)

        return RelationshipMetrics(
            relationshipScore: score,
            averageRating: avgRating,
            totalRated: rated.count,
            categoryStats: categoryStats,
            sentCount: sent,
            receivedCount: received,
            balanceScore: balance,
            weeklyShares: weekly,
            monthlyShares: monthly,
            topCategory: top,
            ratingDistribution: ratingDist
        )
    }

    static func computeAchievements(
        stats: AppStats,
        events: [ShareEvent],
        messageCount: Int,
        currentUserID: String
    ) -> [Achievement] {
        var unlocked = Set<String>()
        var dates: [String: Date] = [:]
        let now = Date()

        let total = stats.platformStats.reduce(0) { $0 + $1.totalExchanged }
        let unviewed = stats.platformStats.reduce(0) { $0 + $1.unviewedCount }
        let fiveStars = events.filter { $0.rating == 5 && $0.receiverID == currentUserID }.count
        let categoriesUsed = Set(events.map(\.category)).count
        let rm = stats.relationshipMetrics

        func unlock(_ id: String) {
            unlocked.insert(id)
            dates[id] = now
        }

        if total >= 1 { unlock("first_share") }
        if total >= 10 { unlock("ten_shares") }
        if total >= 50 { unlock("fifty_shares") }
        if total >= 100 { unlock("hundred_shares") }
        if stats.streakDays >= 7 { unlock("week_streak") }
        if stats.streakDays >= 30 { unlock("month_streak") }
        if unviewed == 0 && total > 0 { unlock("all_caught_up") }
        if fiveStars >= 10 { unlock("five_star") }
        if categoriesUsed >= 5 { unlock("category_explorer") }
        if messageCount >= 25 { unlock("chatterbox") }
        if rm.balanceScore >= 90 && total >= 10 { unlock("balanced") }
        if rm.relationshipScore >= 90 { unlock("soulmate_score") }

        return Achievement.catalog(unlockedIDs: unlocked, unlockDates: dates)
    }

    static func ratingPoints(for rating: Int) -> Int {
        switch rating {
        case 5: return 8
        case 4: return 5
        case 3: return 2
        default: return 0
        }
    }
}

enum PointsSystem {
    struct Level: Identifiable {
        let id: Int
        let name: String
        let minPoints: Int
        let icon: String
        let color: String
    }

    static let levels: [Level] = [
        Level(id: 0, name: "Newcomer", minPoints: 0, icon: "leaf.fill", color: "green"),
        Level(id: 1, name: "Linker", minPoints: 50, icon: "link", color: "blue"),
        Level(id: 2, name: "Sharer", minPoints: 150, icon: "paperplane.fill", color: "purple"),
        Level(id: 3, name: "Connector", minPoints: 350, icon: "bolt.fill", color: "orange"),
        Level(id: 4, name: "Influencer", minPoints: 700, icon: "star.fill", color: "yellow"),
        Level(id: 5, name: "Soulmate", minPoints: 1500, icon: "heart.fill", color: "pink")
    ]

    static func currentLevel(for points: Int) -> Level {
        levels.last { $0.minPoints <= points } ?? levels[0]
    }

    static func nextLevel(for points: Int) -> Level? {
        levels.first { $0.minPoints > points }
    }

    static func progressToNextLevel(points: Int) -> Double {
        guard let next = nextLevel(for: points) else { return 1.0 }
        let current = currentLevel(for: points)
        let range = next.minPoints - current.minPoints
        guard range > 0 else { return 1.0 }
        return Double(points - current.minPoints) / Double(range)
    }

    static func bonusPoints(for streak: Int) -> Int {
        switch streak {
        case 0...2: return 0
        case 3...6: return 5
        case 7...13: return 15
        case 14...29: return 30
        default: return 50
        }
    }

    static func achievementTitles(stats: AppStats) -> [String] {
        stats.relationshipMetrics.relationshipScore >= 60
            ? [stats.relationshipMetrics.scoreLabel]
            : []
    }
}
