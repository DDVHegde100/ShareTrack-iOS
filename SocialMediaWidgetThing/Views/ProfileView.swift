import SwiftUI

struct LogShareView: View {
    @EnvironmentObject var store: SharedDataStore
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlatform: SocialPlatform = .instagram
    @State private var selectedCategory: ContentCategory = .other
    @State private var note = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if store.currentUser?.friendID == nil {
                        noFriendPrompt
                    } else {
                        Text("Log a video you shared")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)

                        Picker("Platform", selection: $selectedPlatform) {
                            ForEach(SocialPlatform.allCases) { platform in
                                Text(platform.displayName).tag(platform)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Category")
                                .font(.headline)
                                .foregroundStyle(theme.primaryText)
                            CategoryPickerGrid(selected: $selectedCategory)
                        }

                        TextField("Optional note...", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .padding()
                            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(theme.primaryText)

                        Button { Task { await logShare() } } label: {
                            if isSending {
                                ProgressView()
                            } else {
                                let pts = selectedPlatform.pointsPerShare + selectedCategory.bonusPoints
                                Text("Log Share (+ \(pts) pts)")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(ThemedScreenBackground())
            .navigationTitle("Log Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var noFriendPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Connect a friend first")
                .font(.headline)
                .foregroundStyle(theme.primaryText)
        }
        .padding(.top, 40)
    }

    private func logShare() async {
        guard store.currentUser?.friendID != nil else { return }
        isSending = true
        defer { isSending = false }

        if ShareEventManager.logShare(
            platform: selectedPlatform,
            category: selectedCategory,
            note: note.isEmpty ? nil : note
        ) != nil {
            store.loadFromDisk()
        }
        dismiss()
    }
}

struct UnviewedVideosView: View {
    let platform: SocialPlatform
    @EnvironmentObject var store: SharedDataStore
    @Environment(\.appTheme) private var theme

    var unviewedEvents: [ShareEvent] {
        guard let userID = store.currentUser?.id else { return [] }
        return store.shareEvents.filter {
            $0.platform == platform && $0.receiverID == userID && !$0.isViewed
        }
    }

    var body: some View {
        List(unviewedEvents) { event in
            NavigationLink {
                ShareDetailView(event: event)
            } label: {
                HStack {
                    Image(systemName: platform.iconName)
                        .foregroundStyle(platform.brandColor)
                    VStack(alignment: .leading) {
                        Text(event.category.displayName)
                            .font(.subheadline.bold())
                            .foregroundStyle(theme.primaryText)
                        Text(event.sharedAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ThemedScreenBackground())
        .navigationTitle("Unviewed")
    }
}
