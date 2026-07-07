import SwiftUI

struct LogShareView: View {
    @EnvironmentObject var store: SharedDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlatform: SocialPlatform = .instagram
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if store.currentUser?.friendID == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Connect a friend first")
                            .font(.headline)
                        Text("Go to the Friend tab and add your person before logging shares.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    Text("Log a video you shared")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Platform", selection: $selectedPlatform) {
                        ForEach(SocialPlatform.allCases) { platform in
                            Text(platform.displayName).tag(platform)
                        }
                    }
                    .pickerStyle(.wheel)

                    Button {
                        Task { await logShare() }
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Log Share (+ \(selectedPlatform.pointsPerShare) pts)")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Log Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func logShare() async {
        guard store.currentUser?.friendID != nil else { return }

        isSending = true
        defer { isSending = false }

        if ShareEventManager.logShare(platform: selectedPlatform) != nil {
            store.loadFromDisk()
        }

        dismiss()
    }
}

struct UnviewedVideosView: View {
    let platform: SocialPlatform
    @EnvironmentObject var store: SharedDataStore

    var unviewedEvents: [ShareEvent] {
        guard let userID = store.currentUser?.id else { return [] }
        return store.shareEvents.filter {
            $0.platform == platform &&
            $0.receiverID == userID &&
            !$0.isViewed
        }
    }

    var body: some View {
        List(unviewedEvents) { event in
            HStack {
                Image(systemName: platform.iconName)
                    .foregroundStyle(platform.brandColor)
                VStack(alignment: .leading) {
                    Text("From your friend")
                        .font(.subheadline.bold())
                    Text(event.sharedAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Mark Viewed") {
                    store.markEventViewed(event.id)
                    Task {
                        try? await CloudKitService.shared.markEventViewedInCloud(event.id)
                    }
                }
                .font(.caption.bold())
            }
        }
        .navigationTitle("Unviewed")
    }
}
