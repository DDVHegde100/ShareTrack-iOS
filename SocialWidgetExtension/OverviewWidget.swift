import WidgetKit
import SwiftUI

struct OverviewWidget: Widget {
    let kind = "OverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OverviewTimelineProvider()) { entry in
            StyledOverviewWidgetContent(
                config: entry.config,
                stats: entry.stats,
                friendName: entry.friendName,
                streak: entry.streak,
                family: entry.family
            )
            .containerBackground(for: .widget) {
                WidgetBackgroundView(config: entry.config)
            }
        }
        .configurationDisplayName("ShareTrack Overview")
        .description("All platforms at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct OverviewTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> OverviewEntry {
        OverviewEntry(date: Date(), config: .default, stats: AppStats.empty, friendName: "Alex", streak: 3, family: context.family)
    }

    func getSnapshot(in context: Context, completion: @escaping (OverviewEntry) -> Void) {
        completion(currentEntry(family: context.family))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OverviewEntry>) -> Void) {
        let entry = currentEntry(family: context.family)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry(family: WidgetFamily) -> OverviewEntry {
        let config = WidgetConfigLoader.load()

        var stats = AppStats.empty
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        if let data = defaults?.data(forKey: AppConstants.UserDefaultsKeys.cachedStatsJSON),
           let decoded = try? JSONDecoder().decode(AppStats.self, from: data) {
            stats = decoded
        }

        var friendName: String?
        if let userData = defaults?.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
            friendName = user.friendUsername
        }

        return OverviewEntry(date: Date(), config: config, stats: stats, friendName: friendName, streak: stats.streakDays, family: family)
    }
}

struct OverviewEntry: TimelineEntry {
    let date: Date
    let config: WidgetConfig
    let stats: AppStats
    let friendName: String?
    let streak: Int
    let family: WidgetFamily
}
