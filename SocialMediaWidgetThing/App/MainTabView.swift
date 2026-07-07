import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ActivityFeedView()
                .tabItem {
                    Label("Activity", systemImage: "clock.fill")
                }
                .tag(1)

            ConnectPlatformsView()
                .tabItem {
                    Label("Connect", systemImage: "link.circle.fill")
                }
                .tag(2)

            FriendView()
                .tabItem {
                    Label("Friend", systemImage: "heart.fill")
                }
                .tag(3)

            WidgetCustomizeView()
                .tabItem {
                    Label("Widget", systemImage: "square.grid.2x2.fill")
                }
                .tag(4)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(5)
        }
        .tint(AppColors.accent)
    }
}
