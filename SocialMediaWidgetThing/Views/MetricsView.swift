import SwiftUI
import Charts

struct MetricsView: View {
    @EnvironmentObject var store: SharedDataStore
    @Environment(\.appTheme) private var theme
    @State private var chartRange: ChartRange = .twoWeeks

    enum ChartRange: String, CaseIterable {
        case week = "7D"
        case twoWeeks = "14D"
        case month = "30D"

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }

    private var metrics: RelationshipMetrics {
        store.stats.relationshipMetrics
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                relationshipScoreCard
                balanceRow
                categorySection
                ratingSection
                timeRangePicker
                achievementsLink
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(ThemedScreenBackground())
        .navigationTitle("Metrics")
        .onChange(of: chartRange) { _, range in
            store.setChartDays(range.days)
        }
    }

    private var relationshipScoreCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(theme.accent.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: CGFloat(metrics.relationshipScore) / 100)
                    .stroke(theme.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(metrics.relationshipScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                    Text("score")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }
            }

            Text(metrics.scoreLabel)
                .font(.title3.bold())
                .foregroundStyle(theme.accent)

            HStack(spacing: 20) {
                miniMetric("Weekly", "\(metrics.weeklyShares)")
                miniMetric("Monthly", "\(metrics.monthlyShares)")
                miniMetric("Rated", String(format: "%.1f★", metrics.averageRating))
            }
        }
        .padding()
        .themedCard()
    }

    private var balanceRow: some View {
        HStack(spacing: 12) {
            balanceCard(title: "You sent", value: metrics.sentCount, icon: "paperplane.fill")
            balanceCard(title: "You got", value: metrics.receivedCount, icon: "tray.fill")
            balanceCard(title: "Balance", value: metrics.balanceScore, icon: "scalemass.fill", suffix: "%")
        }
    }

    private func balanceCard(title: String, value: Int, icon: String, suffix: String = "") -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(theme.accent)
            Text("\(value)\(suffix)")
                .font(.title3.bold())
                .foregroundStyle(theme.primaryText)
            Text(title)
                .font(.caption2)
                .foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .themedCard()
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            let active = metrics.categoryStats.filter { $0.count > 0 }.sorted { $0.count > $1.count }

            if active.isEmpty {
                Text("No categorized shares yet")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .padding()
                    .themedCard()
            } else {
                ForEach(active) { stat in
                    HStack(spacing: 12) {
                        Image(systemName: stat.category.icon)
                            .foregroundStyle(stat.category.color)
                            .frame(width: 28)
                        Text(stat.category.displayName)
                            .font(.subheadline)
                            .foregroundStyle(theme.primaryText)
                        Spacer()
                        Text("\(stat.count)")
                            .font(.headline)
                            .foregroundStyle(theme.primaryText)
                        if stat.averageRating > 0 {
                            Text(String(format: "%.1f★", stat.averageRating))
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .themedCard()
                }
            }
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating Distribution")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            if metrics.ratingDistribution.isEmpty {
                Text("Rate videos when you view them")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .padding()
                    .themedCard()
            } else {
                ForEach((1...5).reversed(), id: \.self) { star in
                    let count = metrics.ratingDistribution[star] ?? 0
                    HStack(spacing: 8) {
                        Text("\(star)★")
                            .font(.caption.bold())
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 28, alignment: .leading)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.accent.opacity(0.8))
                                .frame(width: geo.size.width * barWidth(count: count))
                        }
                        .frame(height: 8)
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
                .padding()
                .themedCard()
            }
        }
    }

    private var timeRangePicker: some View {
        Picker("Range", selection: $chartRange) {
            ForEach(ChartRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var achievementsLink: some View {
        NavigationLink {
            AchievementsView()
        } label: {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Achievements")
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)
                Spacer()
                Text("\(store.achievements.filter(\.isUnlocked).count)/\(store.achievements.count)")
                    .font(.caption.bold())
                    .foregroundStyle(theme.secondaryText)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }
            .padding()
            .themedCard()
        }
    }

    private func miniMetric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(theme.primaryText)
            Text(label)
                .font(.caption2)
                .foregroundStyle(theme.secondaryText)
        }
    }

    private func barWidth(count: Int) -> CGFloat {
        let max = metrics.ratingDistribution.values.max() ?? 1
        return CGFloat(count) / CGFloat(max(max, 1))
    }
}

struct AchievementsView: View {
    @EnvironmentObject var store: SharedDataStore
    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(store.achievements) { achievement in
                    VStack(spacing: 10) {
                        Image(systemName: achievement.icon)
                            .font(.title2)
                            .foregroundStyle(achievement.isUnlocked ? theme.accent : theme.secondaryText.opacity(0.4))
                        Text(achievement.title)
                            .font(.caption.bold())
                            .foregroundStyle(achievement.isUnlocked ? theme.primaryText : theme.secondaryText)
                            .multilineTextAlignment(.center)
                        Text(achievement.description)
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .themedCard()
                    .opacity(achievement.isUnlocked ? 1 : 0.55)
                }
            }
            .padding(16)
        }
        .background(ThemedScreenBackground())
        .navigationTitle("Achievements")
    }
}

struct ShareDetailView: View {
    let event: ShareEvent
    @EnvironmentObject var store: SharedDataStore
    @EnvironmentObject var messages: MessageService
    @Environment(\.appTheme) private var theme
    @State private var rating: Int = 0
    @State private var commentText = ""
    @State private var selectedReaction: ShareReaction?

    private var isReceived: Bool {
        event.receiverID == store.currentUser?.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                        .padding()
                        .themedCard()
                }
                if isReceived {
                    ratingSection
                    reactionSection
                }
                commentsSection
            }
            .padding(16)
        }
        .background(ThemedScreenBackground())
        .navigationTitle("Share Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            rating = event.rating ?? 0
            selectedReaction = event.reaction
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: event.platform.iconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(event.platform.gradient, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(event.platform.displayName)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)
                Label(event.category.displayName, systemImage: event.category.icon)
                    .font(.caption)
                    .foregroundStyle(event.category.color)
                Text(event.sharedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer()
            Text("+\(event.pointsEarned)")
                .font(.caption.bold())
                .foregroundStyle(theme.accent)
        }
        .themedCard()
        .padding(.vertical, 4)
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rate this share")
                .font(.headline)
                .foregroundStyle(theme.primaryText)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = star
                        store.rateEvent(event.id, rating: star, reaction: selectedReaction)
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(star <= rating ? .yellow : theme.secondaryText)
                    }
                }
            }
        }
        .padding()
        .themedCard()
    }

    private var reactionSection: some View {
        HStack(spacing: 12) {
            ForEach(ShareReaction.allCases) { reaction in
                Button {
                    selectedReaction = reaction
                    if rating > 0 {
                        store.rateEvent(event.id, rating: rating, reaction: reaction)
                    }
                } label: {
                    Text(reaction.emoji)
                        .font(.title2)
                        .padding(8)
                        .background(
                            selectedReaction == reaction ? theme.accent.opacity(0.3) : theme.cardBackground,
                            in: Circle()
                        )
                }
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            ForEach(messages.comments(for: event.id)) { comment in
                HStack(alignment: .top) {
                    Text(comment.text)
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryText)
                    Spacer()
                }
                .padding(10)
                .themedCard()
            }

            HStack {
                TextField("Add comment...", text: $commentText)
                    .padding(10)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(theme.primaryText)
                Button("Send") {
                    Task {
                        try? await messages.addComment(shareEventID: event.id, text: commentText)
                        commentText = ""
                    }
                }
                .foregroundStyle(theme.accent)
            }
        }
    }
}

struct CategoryPickerGrid: View {
    @Binding var selected: ContentCategory
    @Environment(\.appTheme) private var theme

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
            ForEach(ContentCategory.allCases) { category in
                Button {
                    selected = category
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.title3)
                            .foregroundStyle(category.color)
                        Text(category.displayName)
                            .font(.caption2.bold())
                            .foregroundStyle(selected == category ? theme.primaryText : theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selected == category ? category.color.opacity(0.25) : theme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selected == category ? category.color : .clear, lineWidth: 1.5)
                    )
                }
            }
        }
    }
}
