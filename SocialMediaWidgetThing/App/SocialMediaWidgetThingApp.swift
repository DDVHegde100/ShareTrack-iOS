import SwiftUI

@main
struct SocialMediaWidgetThingApp: App {
    @StateObject private var store = SharedDataStore.shared
    @StateObject private var cloudKit = CloudKitService.shared
    @StateObject private var discord = DiscordService.shared
    @StateObject private var syncManager = SyncManager.shared
    @StateObject private var clipboard = ClipboardTracker.shared
    @StateObject private var notifications = NotificationService.shared

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(cloudKit)
                .environmentObject(discord)
                .environmentObject(syncManager)
                .environmentObject(clipboard)
                .environmentObject(notifications)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    await notifications.requestAuthorization()
                    await syncManager.syncIfNeeded(store: store, cloudKit: cloudKit)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        clipboard.checkClipboard()
                        Task {
                            await syncManager.syncIfNeeded(store: store, cloudKit: cloudKit)
                        }
                    }
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        Task {
            if url.scheme == "socialwidget", url.host == "discord-callback" {
                if let connection = await discord.handleCallback(url: url) {
                    store.connectPlatform(connection)
                }
            } else if url.scheme == "socialwidget", url.host == "track" {
                handleTrackDeepLink(url)
            }
        }
    }

    private func handleTrackDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let shareURL = URL(string: urlParam) else { return }

        let platform = PlatformURLDetector.detectPlatform(from: shareURL)
        if let event = ShareEventManager.logShare(platform: platform, contentURL: shareURL.absoluteString) {
            store.loadFromDisk()
            notifications.notifyShareLogged(platform: platform, points: event.pointsEarned)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: SharedDataStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: store.hasCompletedOnboarding)
    }
}
