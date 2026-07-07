import SwiftUI
import WidgetKit

struct WidgetGlassCard: ViewModifier {
    let config: WidgetConfig
    let accent: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(cardBorder)
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch config.layout {
        case .glass:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(config.theme.isLightTheme
                    ? Color.white.opacity(0.55)
                    : Color.white.opacity(0.12))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        case .card:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(config.theme.isLightTheme
                    ? Color.white.opacity(0.85)
                    : Color.black.opacity(0.35))
                .shadow(color: accent.opacity(0.25), radius: 8, y: 4)
        case .neon:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .shadow(color: accent.opacity(0.6), radius: 12)
        case .mesh:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(config.theme.isLightTheme
                    ? Color.white.opacity(0.45)
                    : Color.white.opacity(0.08))
        case .outline:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.clear)
        case .flat:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(config.theme.isLightTheme
                    ? Color.black.opacity(0.04)
                    : Color.white.opacity(0.06))
        }
    }

    @ViewBuilder
    private var cardBorder: some View {
        switch config.layout {
        case .glass:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(config.theme.isLightTheme ? 0.8 : 0.35),
                            Color.white.opacity(config.theme.isLightTheme ? 0.2 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        case .neon:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(accent.opacity(0.85), lineWidth: 1.5)
                .shadow(color: accent.opacity(0.5), radius: 6)
        case .outline:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

extension View {
    func widgetGlassCard(config: WidgetConfig, accent: Color, cornerRadius: CGFloat = 14) -> some View {
        modifier(WidgetGlassCard(config: config, accent: accent, cornerRadius: cornerRadius))
    }
}

// MARK: - Widget Background

struct WidgetBackgroundView: View {
    let config: WidgetConfig

    var body: some View {
        ZStack {
            config.theme.backgroundGradient

            if config.layout == .mesh {
                meshOrbs
            }

            if config.layout == .neon {
                accentGlow
            }
        }
    }

    private var meshOrbs: some View {
        let accent = config.resolvedAccent(fallback: config.theme.accentColor)
        return ZStack {
            Circle()
                .fill(accent.opacity(0.35))
                .frame(width: 120, height: 120)
                .blur(radius: 40)
                .offset(x: -40, y: -30)
            Circle()
                .fill(config.theme.gradientColors.last?.opacity(0.5) ?? accent.opacity(0.3))
                .frame(width: 100, height: 100)
                .blur(radius: 35)
                .offset(x: 50, y: 40)
        }
    }

    private var accentGlow: some View {
        let accent = config.resolvedAccent(fallback: config.theme.accentColor)
        return RadialGradient(
            colors: [accent.opacity(0.25), .clear],
            center: .topLeading,
            startRadius: 0,
            endRadius: 180
        )
    }
}

// MARK: - Stat Pill

struct WidgetStatPill: View {
    let label: String
    let value: Int
    let icon: String
    let config: WidgetConfig
    let accent: Color
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(highlight ? .orange : accent.opacity(0.9))
            Text("\(value)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(highlight ? .orange : config.theme.primaryTextColor)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(config.theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .widgetGlassCard(config: config, accent: accent, cornerRadius: 10)
    }
}

// MARK: - Platform Badge

struct WidgetPlatformBadge: View {
    let platform: SocialPlatform
    let config: WidgetConfig

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: platform.iconName)
                .font(.system(size: 10, weight: .semibold))
            Text(platform.displayName)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(config.theme.primaryTextColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule().fill(platform.brandColor.opacity(0.75))
        }
        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - Streak Badge

struct WidgetStreakBadge: View {
    let streak: Int
    let config: WidgetConfig

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 9))
            Text("\(streak)")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.orange.opacity(0.18), in: Capsule())
        .overlay(Capsule().stroke(.orange.opacity(0.35), lineWidth: 0.5))
    }
}

// MARK: - Main Widget Content (Single Platform)

struct StyledShareWidgetContent: View {
    let config: WidgetConfig
    let platform: SocialPlatform
    let stats: PlatformStats
    let friendName: String?
    let streak: Int
    let totalPoints: Int
    let family: WidgetFamily

    private var accent: Color {
        config.resolvedAccent(fallback: config.theme.accentColor)
    }

    var body: some View {
        switch family {
        case .systemSmall: smallLayout
        case .systemMedium: mediumLayout
        case .systemLarge: largeLayout
        default: smallLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: platform.iconName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(platform.brandColor)
                Spacer()
                if streak > 0 { WidgetStreakBadge(streak: streak, config: config) }
            }

            Spacer(minLength: 4)

            Text("\(stats.totalExchanged)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(config.theme.primaryTextColor)

            Text("shared")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(config.theme.secondaryTextColor)

            Spacer(minLength: 4)

            if stats.unviewedCount > 0 {
                HStack(spacing: 4) {
                    Circle().fill(.orange).frame(width: 5, height: 5)
                    Text("\(stats.unviewedCount) unviewed")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.orange.opacity(0.15), in: Capsule())
            }

            StyledMiniChart(data: stats.dailyCounts, accent: accent, config: config)
                .frame(height: 28)
                .padding(.top, 6)
        }
        .padding(12)
    }

    private var mediumLayout: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                WidgetPlatformBadge(platform: platform, config: config)

                Text("\(stats.totalExchanged)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(config.theme.primaryTextColor)

                HStack(spacing: 10) {
                    miniStat("Sent", stats.totalSent, "paperplane.fill")
                    miniStat("Recv", stats.totalReceived, "tray.fill")
                }

                if let friend = friendName {
                    Text("with \(friend)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(config.theme.secondaryTextColor)
                }
            }

            VStack(spacing: 8) {
                if stats.unviewedCount > 0 {
                    VStack(spacing: 2) {
                        Text("\(stats.unviewedCount)")
                            .font(.title2.bold())
                            .foregroundStyle(.orange)
                        Text("new")
                            .font(.system(size: 8))
                            .foregroundStyle(config.theme.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .widgetGlassCard(config: config, accent: .orange, cornerRadius: 12)
                }

                if streak > 0 {
                    WidgetStreakBadge(streak: streak, config: config)
                }

                Spacer()

                StyledMiniChart(data: stats.dailyCounts, accent: accent, config: config)
                    .frame(height: 52)
                    .padding(8)
                    .widgetGlassCard(config: config, accent: accent, cornerRadius: 12)
            }
            .frame(width: 110)
        }
        .padding(14)
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WidgetPlatformBadge(platform: platform, config: config)
                Spacer()
                if streak > 0 { WidgetStreakBadge(streak: streak, config: config) }
            }

            HStack(spacing: 8) {
                WidgetStatPill(label: "Sent", value: stats.totalSent, icon: "paperplane.fill", config: config, accent: accent)
                WidgetStatPill(label: "Received", value: stats.totalReceived, icon: "tray.fill", config: config, accent: accent)
                WidgetStatPill(label: "Total", value: stats.totalExchanged, icon: "arrow.left.arrow.right", config: config, accent: accent)
                if stats.unviewedCount > 0 {
                    WidgetStatPill(label: "New", value: stats.unviewedCount, icon: "eye.slash.fill", config: config, accent: accent, highlight: true)
                }
            }

            StyledMiniChart(data: stats.dailyCounts, accent: accent, config: config, showGrid: true)
                .frame(height: 64)
                .padding(10)
                .widgetGlassCard(config: config, accent: accent, cornerRadius: 14)

            HStack {
                if let friend = friendName {
                    Label(friend, systemImage: "heart.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(config.theme.secondaryTextColor)
                }
                Spacer()
                Text("\(totalPoints) pts")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.15), in: Capsule())
            }
        }
        .padding(14)
    }

    private func miniStat(_ label: String, _ value: Int, _ icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 8))
            Text("\(value)").font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(config.theme.secondaryTextColor)
    }
}

// MARK: - Overview Widget Content

struct StyledOverviewWidgetContent: View {
    let config: WidgetConfig
    let stats: AppStats
    let friendName: String?
    let streak: Int
    let family: WidgetFamily

    private var accent: Color {
        config.resolvedAccent(fallback: config.theme.accentColor)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ShareTrack")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(config.theme.primaryTextColor)
                Spacer()
                if streak > 0 { WidgetStreakBadge(streak: streak, config: config) }
            }

            if family == .systemLarge {
                largeOverview
            } else {
                mediumOverview
            }

            if let friend = friendName {
                Text("with \(friend)")
                    .font(.system(size: 9))
                    .foregroundStyle(config.theme.secondaryTextColor)
            }
        }
        .padding(14)
    }

    private var mediumOverview: some View {
        HStack(spacing: 6) {
            ForEach(SocialPlatform.allCases) { platform in
                let ps = stats.stats(for: platform)
                VStack(spacing: 4) {
                    Image(systemName: platform.iconName)
                        .font(.system(size: 11))
                        .foregroundStyle(platform.brandColor)
                    Text("\(ps.totalExchanged)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(config.theme.primaryTextColor)
                    if ps.unviewedCount > 0 {
                        Circle().fill(.orange).frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .widgetGlassCard(config: config, accent: accent, cornerRadius: 10)
            }
        }
    }

    private var largeOverview: some View {
        VStack(spacing: 6) {
            ForEach(SocialPlatform.allCases) { platform in
                let ps = stats.stats(for: platform)
                HStack(spacing: 8) {
                    Image(systemName: platform.iconName)
                        .font(.system(size: 10))
                        .foregroundStyle(platform.brandColor)
                        .frame(width: 14)

                    Text(platform.displayName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(config.theme.secondaryTextColor)
                        .frame(width: 58, alignment: .leading)

                    StyledMiniChart(data: ps.dailyCounts, accent: platform.brandColor, config: config)
                        .frame(height: 18)

                    Text("\(ps.totalExchanged)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(config.theme.primaryTextColor)
                        .frame(width: 22, alignment: .trailing)

                    if ps.unviewedCount > 0 {
                        Text("\(ps.unviewedCount)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.orange)
                            .frame(width: 14)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .widgetGlassCard(config: config, accent: accent, cornerRadius: 8)
            }

            HStack {
                Spacer()
                Text("\(stats.totalPoints) pts")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent)
            }
        }
    }
}

// MARK: - Styled Chart

struct StyledMiniChart: View {
    let data: [DailyCount]
    let accent: Color
    let config: WidgetConfig
    var showGrid: Bool = false

    var body: some View {
        GeometryReader { geo in
            let maxVal = max(data.map(\.total).max() ?? 1, 1)
            let bars = data.suffix(7)

            ZStack(alignment: .bottom) {
                if showGrid {
                    VStack {
                        ForEach(0..<3, id: \.self) { _ in
                            Spacer()
                            Rectangle()
                                .fill(config.theme.secondaryTextColor.opacity(0.12))
                                .frame(height: 0.5)
                        }
                    }
                }

                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { index, day in
                        let height = max(3, geo.size.height * CGFloat(day.total) / CGFloat(maxVal))
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [accent, accent.opacity(0.45)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: height)
                            .shadow(color: config.layout == .neon ? accent.opacity(0.4) : .clear, radius: 3)
                    }
                }
            }
        }
    }
}
