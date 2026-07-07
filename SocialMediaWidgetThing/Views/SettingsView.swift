import SwiftUI

struct HowToTrackView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                methodCard(
                    number: 1,
                    title: "Share Extension (Best)",
                    icon: "square.and.arrow.up",
                    color: .purple,
                    steps: [
                        "Open a video in Instagram, TikTok, etc.",
                        "Tap the Share button",
                        "Scroll and tap \"Track Share\"",
                        "Done — it logs automatically!"
                    ]
                )

                methodCard(
                    number: 2,
                    title: "Clipboard Detection",
                    icon: "doc.on.clipboard",
                    color: .blue,
                    steps: [
                        "Copy a video link from any social app",
                        "Open ShareTrack",
                        "Tap \"Track Share\" on the banner that appears"
                    ]
                )

                methodCard(
                    number: 3,
                    title: "Manual Log",
                    icon: "plus.circle.fill",
                    color: .green,
                    steps: [
                        "Go to Profile tab",
                        "Tap \"Log a Share\"",
                        "Pick the platform and confirm"
                    ]
                )

                noteSection
            }
            .padding(16)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("How to Track")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tracking Videos")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Social apps don't let third parties read your DMs — so ShareTrack uses these workarounds to count shares between you and your person.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func methodCard(number: Int, title: String, icon: String, color: Color, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text("\(number)")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.5), in: Circle())

                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 16)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var noteSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            Text("Pro tip: After sending a video to your person in any app, immediately use the Share extension. It takes 2 seconds and keeps your stats perfectly accurate.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding()
        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: SharedDataStore
    @EnvironmentObject var clipboard: ClipboardTracker
    @EnvironmentObject var notifications: NotificationService
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.appTheme) private var theme
    @State private var notificationsOn = true
    @State private var showResetConfirm = false
    @State private var showLogShare = false

    var body: some View {
        List {
            Section("Tracking") {
                Button { showLogShare = true } label: {
                    Label("Log a Share", systemImage: "plus.circle.fill")
                }
                NavigationLink { ConnectPlatformsView() } label: {
                    Label("Connect platforms", systemImage: "link.circle.fill")
                }
                Toggle("Clipboard detection", isOn: $clipboard.isEnabled)
                Toggle("Notifications", isOn: $notificationsOn)
                    .onChange(of: notificationsOn) { _, newValue in
                        UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)?
                            .set(newValue, forKey: AppConstants.UserDefaultsKeys.notificationsEnabled)
                        if newValue { Task { await notifications.requestAuthorization() } }
                    }
                NavigationLink { HowToTrackView() } label: {
                    Label("How to track shares", systemImage: "questionmark.circle")
                }
            }

            Section("Appearance") {
                Toggle("Match widget theme", isOn: Binding(
                    get: { themeManager.matchWidgetTheme },
                    set: { themeManager.setMatchWidget($0) }
                ))
                if !themeManager.matchWidgetTheme {
                    Picker("App theme", selection: Binding(
                        get: { themeManager.appThemeOverride },
                        set: { themeManager.setAppThemeOverride($0) }
                    )) {
                        ForEach(WidgetTheme.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                }
                NavigationLink { WidgetCustomizeView() } label: {
                    Label("Widget studio", systemImage: "paintpalette.fill")
                }
            }

            Section("Account") {
                    if let user = store.currentUser {
                        LabeledContent("Username", value: user.username)
                        LabeledContent("Invite Code", value: user.inviteCode)
                        LabeledContent("Points", value: "\(user.totalPoints)")
                    }
                }

                Section("Widget") {
                    LabeledContent("Theme", value: store.widgetConfig.theme.displayName)
                    LabeledContent("Layout", value: store.widgetConfig.layout.displayName)
                    LabeledContent("Accent", value: store.widgetConfig.accentPreset.displayName)
                    LabeledContent("Platform", value: store.widgetPlatform.displayName)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Bundle ID", value: "com.socialmediawidget.thing")
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemedScreenBackground())
            .navigationTitle("Settings")
            .foregroundStyle(theme.primaryText)
            .onAppear {
                notificationsOn = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)?
                    .object(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled) as? Bool ?? true
            }
            .alert("Reset all data?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { resetAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete your profile, friend connection, and all share history.")
            }
            .sheet(isPresented: $showLogShare) {
                LogShareView()
            }
    }

    private func resetAllData() {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        let domain = Bundle.main.bundleIdentifier!
        defaults?.removePersistentDomain(forName: domain)
        AppConstants.allKeys.forEach { defaults?.removeObject(forKey: $0) }

        store.currentUser = nil
        store.shareEvents = []
        store.stats = .empty
        store.hasCompletedOnboarding = false
        store.widgetTheme = .aurora
        store.widgetPlatform = .instagram
        store.widgetConfig = .default
        WidgetConfigLoader.save(.default)
        MessageService.shared.messages = []
        MessageService.shared.comments = []
        MessageStore.save([])
        MessageStore.saveComments([])
    }
}

private extension AppConstants {
    static var allKeys: [String] {
        [
            UserDefaultsKeys.hasCompletedOnboarding,
            UserDefaultsKeys.currentUserID,
            UserDefaultsKeys.widgetTheme,
            UserDefaultsKeys.widgetPlatform,
            UserDefaultsKeys.cachedStatsJSON,
            UserDefaultsKeys.lastStatsUpdate,
            UserDefaultsKeys.widgetConfigJSON,
            UserDefaultsKeys.notificationsEnabled,
            UserDefaultsKeys.clipboardTrackingEnabled,
            "currentUser",
            "shareEvents"
        ]
    }
}
