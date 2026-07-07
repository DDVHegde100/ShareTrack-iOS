import SwiftUI

struct ActivityFeedView: View {
    @EnvironmentObject var store: SharedDataStore
    @State private var filterPlatform: SocialPlatform?

    private var filteredEvents: [ShareEvent] {
        guard let userID = store.currentUser?.id else { return [] }
        var events = store.shareEvents.filter {
            $0.senderID == userID || $0.receiverID == userID
        }
        if let filterPlatform {
            events = events.filter { $0.platform == filterPlatform }
        }
        return events.sorted { $0.sharedAt > $1.sharedAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                platformFilter
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                if filteredEvents.isEmpty {
                    emptyState
                } else {
                    List(filteredEvents) { event in
                        ActivityRow(event: event, currentUserID: store.currentUser?.id ?? "")
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Activity")
        }
    }

    private var platformFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterPlatform == nil) {
                    filterPlatform = nil
                }
                ForEach(SocialPlatform.allCases) { platform in
                    FilterChip(
                        title: platform.displayName,
                        isSelected: filterPlatform == platform,
                        icon: platform.iconName
                    ) {
                        filterPlatform = platform
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
                .foregroundStyle(.white.opacity(0.3))
            Text("No shares yet")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Share a video using the Share extension\nor copy a link and tap Track")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.5))
            NavigationLink {
                HowToTrackView()
            } label: {
                Text("How to track shares")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.accent)
            }
            Spacer()
        }
        .padding()
    }
}

struct ActivityRow: View {
    let event: ShareEvent
    let currentUserID: String

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
                        .foregroundStyle(.white)
                    if !isSent && !event.isViewed {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(event.platform.displayName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Text(event.sharedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("+\(event.pointsEarned)")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.accent)
                if let url = event.contentURL, let link = URL(string: url) {
                    Link(destination: link) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? AppColors.accent : Color.white.opacity(0.08), in: Capsule())
            .foregroundStyle(.white)
        }
    }
}
