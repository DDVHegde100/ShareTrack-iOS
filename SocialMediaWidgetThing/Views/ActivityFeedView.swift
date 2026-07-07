import SwiftUI

struct ActivityFeedView: View {
    @EnvironmentObject var store: SharedDataStore
    @Environment(\.appTheme) private var theme
    @State private var filterPlatform: SocialPlatform?
    @State private var filterCategory: ContentCategory?

    private var filteredEvents: [ShareEvent] {
        guard let userID = store.currentUser?.id else { return [] }
        var events = store.shareEvents.filter {
            $0.senderID == userID || $0.receiverID == userID
        }
        if let filterPlatform { events = events.filter { $0.platform == filterPlatform } }
        if let filterCategory { events = events.filter { $0.category == filterCategory } }
        return events.sorted { $0.sharedAt > $1.sharedAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            platformFilter
                .padding(.horizontal, 16)
                .padding(.top, 8)
            categoryFilter
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            if filteredEvents.isEmpty {
                emptyState
            } else {
                List(filteredEvents) { event in
                    NavigationLink {
                        ShareDetailView(event: event)
                    } label: {
                        ActivityRow(event: event, currentUserID: store.currentUser?.id ?? "")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(ThemedScreenBackground())
        .navigationTitle("Activity")
    }

    private var platformFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterPlatform == nil, theme: theme) {
                    filterPlatform = nil
                }
                ForEach(SocialPlatform.allCases) { platform in
                    FilterChip(title: platform.displayName, isSelected: filterPlatform == platform, icon: platform.iconName, theme: theme) {
                        filterPlatform = platform
                    }
                }
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All types", isSelected: filterCategory == nil, theme: theme) {
                    filterCategory = nil
                }
                ForEach(ContentCategory.allCases) { cat in
                    FilterChip(title: cat.displayName, isSelected: filterCategory == cat, icon: cat.icon, theme: theme) {
                        filterCategory = cat
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(theme.secondaryText.opacity(0.5))
            Text("No shares yet")
                .font(.title3.bold())
                .foregroundStyle(theme.primaryText)
            Text("Share a video using the Share extension\nor copy a link and tap Track")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.secondaryText)
            NavigationLink { HowToTrackView() } label: {
                Text("How to track shares")
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.accent)
            }
            Spacer()
        }
        .padding()
    }
}

struct ActivityRow: View {
    let event: ShareEvent
    let currentUserID: String
    @Environment(\.appTheme) private var theme

    private var isSent: Bool { event.senderID == currentUserID }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: event.platform.iconName)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(event.platform.gradient, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(isSent ? "You sent" : "You received")
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.primaryText)
                    if !isSent && !event.isViewed {
                        Circle().fill(.orange).frame(width: 8, height: 8)
                    }
                }
                HStack(spacing: 6) {
                    Label(event.category.displayName, systemImage: event.category.icon)
                        .font(.caption2)
                        .foregroundStyle(event.category.color)
                    if let reaction = event.reaction {
                        Text(reaction.emoji)
                    }
                    if let rating = event.rating {
                        Text("\(rating)★")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(event.sharedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer()

            Text("+\(event.pointsEarned)")
                .font(.caption.bold())
                .foregroundStyle(theme.accent)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .themedCard()
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    var theme: AppTheme = .default
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption2) }
                Text(title).font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? theme.accent : theme.cardBackground, in: Capsule())
            .foregroundStyle(isSelected ? .white : theme.primaryText)
        }
    }
}
