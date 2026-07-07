import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class SharedDataStore: ObservableObject {
    static let shared = SharedDataStore()

    private let defaults: UserDefaults

    @Published var currentUser: UserProfile?
    @Published var shareEvents: [ShareEvent] = []
    @Published var stats: AppStats = .empty
    @Published var widgetTheme: WidgetTheme = .aurora
    @Published var widgetPlatform: SocialPlatform = .instagram
    @Published var widgetConfig: WidgetConfig = .default
    @Published var achievements: [Achievement] = []
    @Published var chartDays: Int = 14
    @Published var hasCompletedOnboarding: Bool = false

    private init() {
        defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite) ?? .standard
        loadFromDisk()
    }

    func loadFromDisk() {
        hasCompletedOnboarding = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)

        if let userData = defaults.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
            currentUser = user
        }

        if let eventsData = defaults.data(forKey: "shareEvents"),
           let events = try? JSONDecoder().decode([ShareEvent].self, from: eventsData) {
            shareEvents = events
        }

        if let statsData = defaults.data(forKey: AppConstants.UserDefaultsKeys.cachedStatsJSON),
           let cachedStats = try? JSONDecoder().decode(AppStats.self, from: statsData) {
            stats = cachedStats
        }

        if let themeRaw = defaults.string(forKey: AppConstants.UserDefaultsKeys.widgetTheme),
           let theme = WidgetTheme(rawValue: themeRaw) {
            widgetTheme = theme
        }

        if let platformRaw = defaults.string(forKey: AppConstants.UserDefaultsKeys.widgetPlatform),
           let platform = SocialPlatform(rawValue: platformRaw) {
            widgetPlatform = platform
        }

        widgetConfig = WidgetConfigLoader.load()
        widgetTheme = widgetConfig.theme
        chartDays = defaults.integer(forKey: AppConstants.UserDefaultsKeys.chartDays)
        if chartDays == 0 { chartDays = 14 }

        refreshStats()
    }

    func saveUser(_ user: UserProfile) {
        currentUser = user
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: "currentUser")
            defaults.set(user.id, forKey: AppConstants.UserDefaultsKeys.currentUserID)
        }
    }

    func saveEvents(_ events: [ShareEvent]) {
        shareEvents = events
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: "shareEvents")
        }
        refreshStats()
        syncWidgetData()
    }

    func addShareEvent(_ event: ShareEvent) {
        if let _ = ShareEventManager.logShare(
            platform: event.platform,
            contentURL: event.contentURL,
            senderID: event.senderID,
            receiverID: event.receiverID
        ) {
            loadFromDisk()
        }
    }

    func markEventViewed(_ eventID: String) {
        var events = shareEvents
        guard let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        events[index].isViewed = true
        saveEvents(events)
    }

    func rateEvent(_ eventID: String, rating: Int, reaction: ShareReaction? = nil) {
        var events = shareEvents
        guard let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        events[index].rating = min(5, max(1, rating))
        events[index].reaction = reaction
        if !events[index].isViewed { events[index].isViewed = true }

        if var user = currentUser {
            user.totalPoints += MetricsEngine.ratingPoints(for: rating)
            saveUser(user)
        }

        saveEvents(events)
        Task {
            try? await CloudKitService.shared.updateShareEvent(events[index])
        }
    }

    func setChartDays(_ days: Int) {
        chartDays = days
        defaults.set(days, forKey: AppConstants.UserDefaultsKeys.chartDays)
        refreshStats()
    }

    func completeOnboarding(username: String) {
        let user = UserProfile(username: username)
        saveUser(user)
        hasCompletedOnboarding = true
        defaults.set(true, forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
    }

    func createUser(username: String) {
        let user = UserProfile(username: username)
        saveUser(user)
    }

    func finishSetup() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
    }

    func connectPlatform(_ connection: PlatformConnection) {
        guard var user = currentUser else { return }
        user.connectedPlatforms.removeAll { $0.platform == connection.platform }
        user.connectedPlatforms.append(connection)
        saveUser(user)
    }

    func disconnectPlatform(_ platform: SocialPlatform) {
        guard var user = currentUser else { return }
        user.connectedPlatforms.removeAll { $0.platform == platform }
        saveUser(user)
    }

    func setFriend(friendID: String, friendUsername: String) {
        guard var user = currentUser else { return }
        user.friendID = friendID
        user.friendUsername = friendUsername
        saveUser(user)
    }

    func removeFriend() {
        guard var user = currentUser else { return }
        user.friendID = nil
        user.friendUsername = nil
        saveUser(user)
    }

    func setWidgetTheme(_ theme: WidgetTheme) {
        widgetTheme = theme
        widgetConfig.theme = theme
        saveWidgetConfig()
    }

    func setWidgetLayout(_ layout: WidgetLayoutStyle) {
        widgetConfig.layout = layout
        saveWidgetConfig()
    }

    func setWidgetAccent(_ preset: WidgetAccentPreset, customColor: Color? = nil) {
        widgetConfig.accentPreset = preset
        if let customColor, preset == .custom {
            let ui = UIColor(customColor)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: &a)
            widgetConfig.customAccentRed = Double(r)
            widgetConfig.customAccentGreen = Double(g)
            widgetConfig.customAccentBlue = Double(b)
        }
        saveWidgetConfig()
    }

    func saveWidgetConfig() {
        widgetTheme = widgetConfig.theme
        defaults.set(widgetConfig.theme.rawValue, forKey: AppConstants.UserDefaultsKeys.widgetTheme)
        WidgetConfigLoader.save(widgetConfig)
        syncWidgetData()
    }

    func setWidgetPlatform(_ platform: SocialPlatform) {
        widgetPlatform = platform
        defaults.set(platform.rawValue, forKey: AppConstants.UserDefaultsKeys.widgetPlatform)
        syncWidgetData()
    }

    func refreshStats() {
        guard let user = currentUser else {
            stats = .empty
            achievements = []
            return
        }
        let messageCount = MessageService.shared.messages.count
        stats = StatsCalculator.calculate(
            events: shareEvents,
            currentUserID: user.id,
            totalPoints: user.totalPoints,
            chartDays: chartDays,
            messageCount: messageCount
        )
        achievements = MetricsEngine.computeAchievements(
            stats: stats,
            events: shareEvents,
            messageCount: messageCount,
            currentUserID: user.id
        )
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: AppConstants.UserDefaultsKeys.cachedStatsJSON)
        }
        defaults.set(Date(), forKey: AppConstants.UserDefaultsKeys.lastStatsUpdate)
    }

    func syncWidgetData() {
        refreshStats()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func importEvents(_ events: [ShareEvent]) {
        var merged = shareEvents
        for event in events {
            if !merged.contains(where: { $0.id == event.id }) {
                merged.append(event)
            }
        }
        saveEvents(merged)
    }
}

enum StatsCalculator {
    static func calculate(
        events: [ShareEvent],
        currentUserID: String,
        totalPoints: Int,
        chartDays: Int = 14,
        messageCount: Int = 0
    ) -> AppStats {
        var platformStatsMap: [SocialPlatform: PlatformStats] = [:]
        var platformRatings: [SocialPlatform: [Int]] = [:]
        for platform in SocialPlatform.allCases {
            platformStatsMap[platform] = PlatformStats.empty(for: platform)
        }

        let calendar = Calendar.current
        var dailyMap: [SocialPlatform: [String: DailyCount]] = [:]

        for event in events {
            guard var stats = platformStatsMap[event.platform] else { continue }

            if event.senderID == currentUserID {
                stats.totalSent += 1
            } else if event.receiverID == currentUserID {
                stats.totalReceived += 1
                if !event.isViewed {
                    stats.unviewedCount += 1
                }
            }

            stats.pointsEarned += event.pointsEarned
            if let rating = event.rating {
                platformRatings[event.platform, default: []].append(rating)
            }
            platformStatsMap[event.platform] = stats

            let dateKey = DailyCount(date: event.sharedAt, sent: 0, received: 0).dateKey
            if dailyMap[event.platform] == nil {
                dailyMap[event.platform] = [:]
            }

            var daily = dailyMap[event.platform]![dateKey]
                ?? DailyCount(date: calendar.startOfDay(for: event.sharedAt), sent: 0, received: 0)

            if event.senderID == currentUserID {
                daily.sent += 1
            } else if event.receiverID == currentUserID {
                daily.received += 1
            }
            dailyMap[event.platform]![dateKey] = daily
        }

        var result: [PlatformStats] = []
        for platform in SocialPlatform.allCases {
            var stats = platformStatsMap[platform] ?? PlatformStats.empty(for: platform)
            let dailies = dailyMap[platform]?.values.sorted { $0.date < $1.date } ?? []
            stats.dailyCounts = fillMissingDays(dailies, days: chartDays)
            let ratings = platformRatings[platform] ?? []
            stats.averageRating = ratings.isEmpty ? 0 : Double(ratings.reduce(0, +)) / Double(ratings.count)
            result.append(stats)
        }

        let streak = calculateStreak(events: events, userID: currentUserID)
        let relationship = MetricsEngine.computeRelationshipMetrics(
            events: events,
            currentUserID: currentUserID,
            messageCount: messageCount
        )

        return AppStats(
            platformStats: result,
            totalPoints: totalPoints,
            streakDays: streak,
            lastUpdated: Date(),
            relationshipMetrics: relationship
        )
    }

    static func fillMissingDays(_ counts: [DailyCount], days: Int) -> [DailyCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [DailyCount] = []
        let lookup = Dictionary(uniqueKeysWithValues: counts.map { ($0.dateKey, $0) })

        for offset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = DailyCount(date: date, sent: 0, received: 0).dateKey
            result.append(lookup[key] ?? DailyCount(date: date, sent: 0, received: 0))
        }
        return result
    }

    static func calculateStreak(events: [ShareEvent], userID: String) -> Int {
        let calendar = Calendar.current
        let userEvents = events.filter { $0.senderID == userID || $0.receiverID == userID }
        guard !userEvents.isEmpty else { return 0 }

        let activeDays = Set(userEvents.map { calendar.startOfDay(for: $0.sharedAt) })
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while activeDays.contains(checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }
        return streak
    }
}
