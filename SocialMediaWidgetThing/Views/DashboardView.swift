import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var store: SharedDataStore
    @EnvironmentObject var cloudKit: CloudKitService
    @Environment(\.appTheme) private var theme
    @State private var selectedPlatform: SocialPlatform = .instagram
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                QuickTrackBanner()
                headerSection
                relationshipCard
                platformPicker
                statsCards
                chartSection
                unviewedSection
                pointsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(ThemedScreenBackground())
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await refresh() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
            }
        }
        .refreshable { await refresh() }
    }

    private var relationshipCard: some View {
        let m = store.stats.relationshipMetrics
        return NavigationLink {
            MetricsView()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Relationship Score")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                    Text("\(m.relationshipScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                    Text(m.scoreLabel)
                        .font(.caption.bold())
                        .foregroundStyle(theme.accent)
                }
                Spacer()
                if let top = m.topCategory {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Top category")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryText)
                        Label(top.displayName, systemImage: top.icon)
                            .font(.caption.bold())
                            .foregroundStyle(top.color)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }
            .padding()
            .themedCard()
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hey, \(store.currentUser?.username ?? "")")
                    .font(.title2.bold())
                    .foregroundStyle(theme.primaryText)
                if let friend = store.currentUser?.friendUsername {
                    Text("Sharing with \(friend)")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                } else {
                    Text("Add a friend to start tracking")
                        .font(.subheadline)
                        .foregroundStyle(.orange.opacity(0.8))
                }
            }
            Spacer()
            if store.stats.streakDays > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(store.stats.streakDays)")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.2), in: Capsule())
            }
        }
        .padding(.top, 8)
    }

    private var platformPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SocialPlatform.allCases) { platform in
                    PlatformChip(
                        platform: platform,
                        isSelected: selectedPlatform == platform,
                        isConnected: store.currentUser?.connection(for: platform) != nil
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPlatform = platform
                        }
                    }
                }
            }
        }
    }

    private var currentStats: PlatformStats {
        store.stats.stats(for: selectedPlatform)
    }

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(title: "Sent", value: currentStats.totalSent, icon: "paperplane.fill", color: selectedPlatform.brandColor)
            StatCard(title: "Received", value: currentStats.totalReceived, icon: "tray.fill", color: .blue)
            StatCard(title: "Total", value: currentStats.totalExchanged, icon: "arrow.left.arrow.right", color: .purple)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 14 Days")
                .font(.headline)
                .foregroundStyle(.white)

            Chart(currentStats.dailyCounts) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Count", day.total)
                )
                .foregroundStyle(selectedPlatform.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel(format: .dateTime.day())
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(height: 180)
            .padding()
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var unviewedSection: some View {
        if currentStats.unviewedCount > 0 {
            HStack {
                Image(systemName: "eye.slash.fill")
                    .foregroundStyle(.orange)
                Text("\(currentStats.unviewedCount) unviewed videos")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                NavigationLink("View All") {
                    UnviewedVideosView(platform: selectedPlatform)
                }
                .font(.caption.bold())
                .foregroundStyle(.purple)
            }
            .padding()
            .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var pointsSection: some View {
        let level = PointsSystem.currentLevel(for: store.stats.totalPoints)
        let progress = PointsSystem.progressToNextLevel(points: store.stats.totalPoints)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: level.icon)
                    .foregroundStyle(.yellow)
                Text(level.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(store.stats.totalPoints) pts")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.7))
            }

            ProgressView(value: progress)
                .tint(.purple)

            if let next = PointsSystem.nextLevel(for: store.stats.totalPoints) {
                Text("\(next.minPoints - store.stats.totalPoints) points to \(next.name)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            let achievements = PointsSystem.achievementTitles(stats: store.stats)
            if !achievements.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(achievements, id: \.self) { title in
                            Text(title)
                                .font(.caption2.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.purple.opacity(0.3), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await SyncManager.shared.performSync(store: store, cloudKit: cloudKit)
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct PlatformChip: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let isConnected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: platform.iconName)
                    .font(.caption)
                Text(platform.displayName)
                    .font(.caption.bold())
                if isConnected {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ? AnyShapeStyle(platform.gradient) : AnyShapeStyle(Color.white.opacity(0.08)),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        }
    }
}
