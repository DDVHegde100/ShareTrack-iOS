import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @EnvironmentObject var messages: MessageService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                ActivityFeedView()
            }
            .tabItem { Label("Activity", systemImage: "clock.fill") }
            .tag(1)

            NavigationStack {
                ChatView()
            }
            .tabItem { Label("Chat", systemImage: "bubble.left.fill") }
            .tag(2)
            .badge(messages.unreadCount > 0 ? messages.unreadCount : 0)

            NavigationStack {
                FriendView()
            }
            .tabItem { Label("Friend", systemImage: "heart.fill") }
            .tag(3)

            NavigationStack {
                WidgetCustomizeView()
            }
            .tabItem { Label("Widget", systemImage: "square.grid.2x2.fill") }
            .tag(4)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(5)
        }
        .tint(themeManager.currentTheme.accent)
        .environment(\.appTheme, themeManager.currentTheme)
    }
}
