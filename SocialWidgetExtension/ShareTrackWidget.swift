import WidgetKit
import SwiftUI

struct ShareTrackWidget: Widget {
    let kind = "ShareTrackWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShareTrackTimelineProvider()) { entry in
            StyledShareWidgetContent(
                config: entry.config,
                platform: entry.platform,
                stats: entry.stats,
                friendName: entry.friendName,
                streak: entry.streak,
                totalPoints: entry.totalPoints,
                family: entry.family
            )
            .containerBackground(for: .widget) {
                WidgetBackgroundView(config: entry.config)
            }
        }
        .configurationDisplayName("ShareTrack")
        .description("Track videos shared with your person.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct SocialWidgetExtensionEntry: WidgetBundle {
    var body: some Widget {
        ShareTrackWidget()
        OverviewWidget()
    }
}

struct ShareTrackTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShareTrackEntry {
        ShareTrackEntry(
            date: Date(),
            config: .default,
            platform: .instagram,
            stats: sampleStats,
            friendName: "Alex",
            streak: 5,
            totalPoints: 120,
            family: context.family
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShareTrackEntry) -> Void) {
        completion(currentEntry(family: context.family))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShareTrackEntry>) -> Void) {
        let entry = currentEntry(family: context.family)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry(family: WidgetFamily) -> ShareTrackEntry {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        let config = WidgetConfigLoader.load()

        let platformRaw = defaults?.string(forKey: AppConstants.UserDefaultsKeys.widgetPlatform) ?? SocialPlatform.instagram.rawValue
        let platform = SocialPlatform(rawValue: platformRaw) ?? .instagram

        var stats = AppStats.empty
        if let statsData = defaults?.data(forKey: AppConstants.UserDefaultsKeys.cachedStatsJSON),
           let decoded = try? JSONDecoder().decode(AppStats.self, from: statsData) {
            stats = decoded
        }

        var friendName: String?
        if let userData = defaults?.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
            friendName = user.friendUsername
        }

        return ShareTrackEntry(
            date: Date(),
            config: config,
            platform: platform,
            stats: stats.stats(for: platform),
            friendName: friendName,
            streak: stats.streakDays,
            totalPoints: stats.totalPoints,
            family: family
        )
    }

    private var sampleStats: PlatformStats {
        var stats = PlatformStats.empty(for: .instagram)
        stats.totalSent = 24
        stats.totalReceived = 31
        stats.unviewedCount = 3
        stats.dailyCounts = (0..<14).map { offset in
            DailyCount(
                date: Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date(),
                sent: Int.random(in: 0...5),
                received: Int.random(in: 0...7)
            )
        }.reversed()
        return stats
    }
}

struct ShareTrackEntry: TimelineEntry {
    let date: Date
    let config: WidgetConfig
    let platform: SocialPlatform
    let stats: PlatformStats
    let friendName: String?
    let streak: Int
    let totalPoints: Int
    let family: WidgetFamily
}
