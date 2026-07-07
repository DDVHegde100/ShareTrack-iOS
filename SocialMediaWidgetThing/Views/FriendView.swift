import SwiftUI

struct FriendView: View {
    @EnvironmentObject var store: SharedDataStore
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var inviteCodeInput = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let user = store.currentUser, user.hasFriend {
                        connectedFriendView(user: user)
                    } else {
                        noFriendView
                    }
                }
                .padding(16)
            }
            .background(Color(red: 0.06, green: 0.06, blue: 0.10).ignoresSafeArea())
            .navigationTitle("Your Person")
        }
    }

    private func connectedFriendView(user: UserProfile) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
            }
            .shadow(color: .pink.opacity(0.4), radius: 20)

            VStack(spacing: 8) {
                Text(user.friendUsername ?? "Friend")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("Connected")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            combinedStatsView

            Button("Remove Friend", role: .destructive) {
                store.removeFriend()
            }
            .font(.subheadline)
        }
    }

    private var combinedStatsView: some View {
        let totalExchanged = store.stats.platformStats.reduce(0) { $0 + $1.totalExchanged }
        let totalUnviewed = store.stats.platformStats.reduce(0) { $0 + $1.unviewedCount }

        return VStack(spacing: 16) {
            HStack(spacing: 16) {
                FriendStatBox(title: "Videos Shared", value: "\(totalExchanged)", icon: "film.fill")
                FriendStatBox(title: "Unviewed", value: "\(totalUnviewed)", icon: "eye.slash.fill")
            }
            HStack(spacing: 16) {
                FriendStatBox(title: "Points", value: "\(store.stats.totalPoints)", icon: "star.fill")
                FriendStatBox(title: "Streak", value: "\(store.stats.streakDays)d", icon: "flame.fill")
            }
        }
    }

    private var noFriendView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.purple.opacity(0.6))

                Text("Add Your Person")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("You can connect with one special friend.\nShare your invite code or enter theirs.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.6))
            }

            if let code = store.currentUser?.inviteCode {
                VStack(spacing: 8) {
                    Text("Your Invite Code")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))

                    Text(code)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .tracking(8)
                        .padding()
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Label("Copy Code", systemImage: "doc.on.doc")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.purple)
                }
            }

            HStack {
                Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
                Text("OR")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.4))
                Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
            }

            VStack(spacing: 12) {
                TextField("Enter friend's code", text: $inviteCodeInput)
                    .textFieldStyle(GlassTextFieldStyle())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await connectFriend() }
                } label: {
                    if isConnecting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Connect")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(inviteCodeInput.count < 6 || isConnecting)
            }
        }
    }

    private func connectFriend() async {
        guard let user = store.currentUser else { return }
        isConnecting = true
        errorMessage = nil
        defer { isConnecting = false }

        do {
            let updated = try await cloudKit.connectWithFriend(
                inviteCode: inviteCodeInput.uppercased(),
                currentUser: user
            )
            store.setFriend(friendID: updated.friendID!, friendUsername: updated.friendUsername!)
            store.saveUser(updated)
            inviteCodeInput = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct FriendStatBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}
