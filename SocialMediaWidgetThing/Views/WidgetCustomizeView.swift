import SwiftUI
import WidgetKit

struct WidgetCustomizeView: View {
    @EnvironmentObject var store: SharedDataStore
    @State private var previewConfig: WidgetConfig = .default
    @State private var previewPlatform: SocialPlatform = .instagram
    @State private var previewSize: PreviewSize = .medium
    @State private var customAccentColor: Color = Color(red: 0.55, green: 0.35, blue: 0.95)

    enum PreviewSize: String, CaseIterable {
        case small, medium, large
        var label: String { rawValue.capitalized }
        var height: CGFloat {
            switch self {
            case .small: return 155
            case .medium: return 160
            case .large: return 220
            }
        }
        var widgetFamily: WidgetFamily {
            switch self {
            case .small: return .systemSmall
            case .medium: return .systemMedium
            case .large: return .systemLarge
            }
        }
    }

    private var accent: Color {
        previewConfig.resolvedAccent(fallback: previewConfig.theme.accentColor)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    livePreviewSection
                    layoutStyleSection
                    themeGallerySection
                    accentColorSection
                    platformSection
                    installSection
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Widget Studio")
            .onAppear { loadPreviewState() }
        }
    }

    // MARK: - Live Preview

    private var livePreviewSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Live Preview")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Picker("Size", selection: $previewSize) {
                    ForEach(PreviewSize.allCases, id: \.self) { size in
                        Text(size.label).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.3))
                    .padding(-8)

                ZStack {
                    WidgetBackgroundView(config: previewConfig)
                    if previewSize == .large && previewPlatform == store.widgetPlatform {
                        StyledShareWidgetContent(
                            config: previewConfig,
                            platform: previewPlatform,
                            stats: store.stats.stats(for: previewPlatform),
                            friendName: store.currentUser?.friendUsername ?? "Friend",
                            streak: store.stats.streakDays,
                            totalPoints: store.stats.totalPoints,
                            family: previewSize.widgetFamily
                        )
                    } else if previewSize != .large {
                        StyledShareWidgetContent(
                            config: previewConfig,
                            platform: previewPlatform,
                            stats: store.stats.stats(for: previewPlatform),
                            friendName: store.currentUser?.friendUsername ?? "Friend",
                            streak: max(store.stats.streakDays, 3),
                            totalPoints: store.stats.totalPoints,
                            family: previewSize.widgetFamily
                        )
                    } else {
                        StyledOverviewWidgetContent(
                            config: previewConfig,
                            stats: store.stats.totalPoints > 0 ? store.stats : sampleStats,
                            friendName: store.currentUser?.friendUsername ?? "Friend",
                            streak: max(store.stats.streakDays, 3),
                            family: .systemLarge
                        )
                    }
                }
                .frame(height: previewSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .shadow(color: accent.opacity(0.45), radius: 20, y: 8)

            HStack(spacing: 12) {
                previewTag(previewConfig.layout.displayName, icon: previewConfig.layout.icon)
                previewTag(previewConfig.theme.displayName, icon: "paintpalette.fill")
                previewTag(previewConfig.accentPreset.displayName, icon: "circle.fill", color: accent)
            }
        }
    }

    private func previewTag(_ text: String, icon: String, color: Color = .white) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundStyle(color)
            Text(text).font(.caption2.bold())
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.08), in: Capsule())
    }

    // MARK: - Layout Styles

    private var layoutStyleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Layout Style", subtitle: "Glass cards, neon glow, mesh & more")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WidgetLayoutStyle.allCases) { layout in
                        LayoutStyleCard(
                            layout: layout,
                            theme: previewConfig.theme,
                            isSelected: previewConfig.layout == layout
                        ) {
                            previewConfig.layout = layout
                            store.setWidgetLayout(layout)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Theme Gallery

    private var themeGallerySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Color Themes", subtitle: "\(WidgetTheme.allCases.count) aesthetic palettes")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                ForEach(WidgetTheme.allCases) { theme in
                    ThemeSwatchCard(
                        theme: theme,
                        layout: previewConfig.layout,
                        isSelected: previewConfig.theme == theme
                    ) {
                        previewConfig.theme = theme
                        store.setWidgetTheme(theme)
                    }
                }
            }
        }
    }

    // MARK: - Accent Colors

    private var accentColorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Accent Color", subtitle: "Charts, glows & highlights")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WidgetAccentPreset.allCases) { preset in
                        AccentColorButton(
                            preset: preset,
                            themeAccent: previewConfig.theme.accentColor,
                            isSelected: previewConfig.accentPreset == preset
                        ) {
                            previewConfig.accentPreset = preset
                            store.setWidgetAccent(preset, customColor: preset == .custom ? customAccentColor : nil)
                        }
                    }
                }
            }

            if previewConfig.accentPreset == .custom {
                ColorPicker("Custom accent", selection: $customAccentColor, supportsOpacity: false)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                    .onChange(of: customAccentColor) { _, newColor in
                        store.setWidgetAccent(.custom, customColor: newColor)
                    }
            }
        }
    }

    // MARK: - Platform

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Default Platform", subtitle: "Shown on the single-platform widget")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SocialPlatform.allCases) { platform in
                        Button {
                            previewPlatform = platform
                            store.setWidgetPlatform(platform)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: platform.iconName)
                                Text(platform.displayName)
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                previewPlatform == platform
                                    ? AnyShapeStyle(platform.gradient)
                                    : AnyShapeStyle(Color.white.opacity(0.08)),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                            .overlay(
                                Capsule().stroke(previewPlatform == platform ? Color.white.opacity(0.3) : .clear, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Install

    private var installSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Add to Home Screen")

            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(number: 1, text: "Long-press your home screen")
                InstructionRow(number: 2, text: "Tap + and search \"ShareTrack\"")
                InstructionRow(number: 3, text: "ShareTrack = single platform · Overview = all platforms")
                InstructionRow(number: 4, text: "Customize here first — widgets update automatically")
            }
            .padding()
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func sectionHeader(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }

    private func loadPreviewState() {
        previewConfig = store.widgetConfig
        previewPlatform = store.widgetPlatform
        customAccentColor = Color(
            red: store.widgetConfig.customAccentRed,
            green: store.widgetConfig.customAccentGreen,
            blue: store.widgetConfig.customAccentBlue
        )
    }

    private var sampleStats: AppStats {
        var stats = AppStats.empty
        stats.totalPoints = 240
        stats.streakDays = 7
        stats.platformStats = SocialPlatform.allCases.map { platform in
            var ps = PlatformStats.empty(for: platform)
            ps.totalSent = Int.random(in: 5...20)
            ps.totalReceived = Int.random(in: 5...25)
            ps.unviewedCount = platform == .tiktok ? 2 : 0
            ps.dailyCounts = (0..<14).map { offset in
                DailyCount(
                    date: Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date(),
                    sent: Int.random(in: 0...4),
                    received: Int.random(in: 0...5)
                )
            }.reversed()
            return ps
        }
        return stats
    }
}

// MARK: - Layout Style Card

struct LayoutStyleCard: View {
    let layout: WidgetLayoutStyle
    let theme: WidgetTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.backgroundGradient)
                        .frame(width: 90, height: 70)

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(layout == .glass ? Color.white.opacity(0.2) : Color.black.opacity(0.3))
                        .frame(width: 50, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(layout == .neon ? theme.accentColor : Color.white.opacity(0.3), lineWidth: layout == .neon ? 1.5 : 0.5)
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 2)
                )

                VStack(spacing: 2) {
                    Image(systemName: layout.icon)
                        .font(.caption2)
                    Text(layout.displayName)
                        .font(.caption2.bold())
                }
                .foregroundStyle(isSelected ? theme.accentColor : .white.opacity(0.7))
            }
        }
    }
}

// MARK: - Theme Swatch

struct ThemeSwatchCard: View {
    let theme: WidgetTheme
    let layout: WidgetLayoutStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.backgroundGradient)
                        .frame(height: 64)

                    // Mini glass card preview
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(theme.isLightTheme ? Color.white.opacity(0.5) : Color.white.opacity(0.12))
                        .frame(width: 36, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                        )
                        .offset(y: 8)

                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: 8, height: 8)
                        .offset(x: 28, y: -20)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 2.5)
                )
                .shadow(color: isSelected ? theme.accentColor.opacity(0.4) : .clear, radius: 8)

                Text(theme.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Accent Button

struct AccentColorButton: View {
    let preset: WidgetAccentPreset
    let themeAccent: Color
    let isSelected: Bool
    let action: () -> Void

    private var swatchColor: Color {
        preset == .auto ? themeAccent : preset.color
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if preset == .custom {
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                                    center: .center
                                )
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(swatchColor)
                            .frame(width: 36, height: 36)
                    }

                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 2.5)
                            .frame(width: 36, height: 36)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                Text(preset == .auto ? "Auto" : preset.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            }
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AppColors.accent.opacity(0.5), in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
