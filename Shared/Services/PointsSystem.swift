import Foundation

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
        var achievements: [String] = []
        let total = stats.platformStats.reduce(0) { $0 + $1.totalExchanged }

        if total >= 1 { achievements.append("First Share") }
        if total >= 10 { achievements.append("Getting Started") }
        if total >= 50 { achievements.append("Content Couple") }
        if total >= 100 { achievements.append("Share Masters") }
        if stats.streakDays >= 7 { achievements.append("Week Streak") }
        if stats.streakDays >= 30 { achievements.append("Monthly Streak") }

        let unviewed = stats.platformStats.reduce(0) { $0 + $1.unviewedCount }
        if unviewed == 0 && total > 0 { achievements.append("All Caught Up") }

        return achievements
    }
}
