import SwiftUI

struct ConnectPlatformsView: View {
    @EnvironmentObject var store: SharedDataStore
    @EnvironmentObject var discord: DiscordService
    @State private var selectedPlatform: SocialPlatform?
    @State private var handleInput = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    infoBanner

                    ForEach(SocialPlatform.allCases) { platform in
                        PlatformConnectionCard(
                            platform: platform,
                            connection: store.currentUser?.connection(for: platform),
                            onConnect: { selectedPlatform = platform },
                            onDisconnect: { store.disconnectPlatform(platform) }
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(red: 0.06, green: 0.06, blue: 0.10).ignoresSafeArea())
            .navigationTitle("Connect")
            .sheet(item: $selectedPlatform) { platform in
                ConnectPlatformSheet(
                    platform: platform,
                    handleInput: $handleInput,
                    onConnect: { handle in
                        connectPlatform(platform, handle: handle)
                        selectedPlatform = nil
                        handleInput = ""
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text("Connect your accounts, then use the Share extension when sending videos to track them automatically.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func connectPlatform(_ platform: SocialPlatform, handle: String) {
        if platform == .discord, discord.authURL != nil {
            // Discord OAuth handled via URL scheme
            return
        }
        let normalized = PlatformConnectionHelper.normalizeHandle(handle)
        let connection = PlatformConnection(platform: platform, handle: normalized, isVerified: false)
        store.connectPlatform(connection)
        Task {
            if var user = store.currentUser {
                try? await CloudKitService.shared.publishUser(user)
            }
        }
    }
}

struct PlatformConnectionCard: View {
    let platform: SocialPlatform
    let connection: PlatformConnection?
    let onConnect: () -> Void
    let onDisconnect: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: platform.iconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(platform.gradient, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(platform.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                if let connection {
                    HStack(spacing: 4) {
                        Text("@\(connection.handle)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        if connection.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                } else {
                    Text("Not connected")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            if connection != nil {
                Button("Disconnect", role: .destructive, action: onDisconnect)
                    .font(.caption.bold())
            } else {
                Button("Connect", action: onConnect)
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(platform.gradient, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ConnectPlatformSheet: View {
    let platform: SocialPlatform
    @Binding var handleInput: String
    let onConnect: (String) -> Void
    @EnvironmentObject var discord: DiscordService
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(platform.gradient, in: RoundedRectangle(cornerRadius: 20))

                Text("Connect \(platform.displayName)")
                    .font(.title2.bold())

                if platform == .discord, let authURL = discord.authURL {
                    Link(destination: authURL) {
                        Text("Sign in with Discord")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.34, green: 0.40, blue: 0.95), in: RoundedRectangle(cornerRadius: 14))
                    }
                    Text("Or enter your username manually:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Username or handle", text: $handleInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button("Connect") {
                    if let error = PlatformConnectionHelper.validateHandle(handleInput, for: platform) {
                        errorMessage = error
                    } else {
                        onConnect(handleInput)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(handleInput.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
