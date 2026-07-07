import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: SharedDataStore
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var username = ""
    @State private var inviteCodeInput = ""
    @State private var currentPage = 0
    @State private var isConnectingFriend = false
    @State private var friendError: String?
    @State private var pendingUsername: String?
    @FocusState private var isUsernameFocused: Bool

    private let totalPages = 4

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    featuresPage.tag(1)
                    usernamePage.tag(2)
                    invitePage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                pageIndicator
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            if store.currentUser != nil && !store.hasCompletedOnboarding {
                currentPage = 3
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.5), radius: 20)

            Text("ShareTrack")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Track the videos you share\nwith your favorite person")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Button("Get Started") {
                withAnimation { currentPage = 1 }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }

    private var featuresPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How it works")
                .font(.title.bold())
                .foregroundStyle(.white)

            VStack(spacing: 20) {
                FeatureRow(icon: "person.crop.circle.badge.plus", title: "Create your profile", subtitle: "Pick a unique username")
                FeatureRow(icon: "link.circle.fill", title: "Connect socials", subtitle: "Instagram, TikTok, Discord & more")
                FeatureRow(icon: "heart.fill", title: "Add your person", subtitle: "One special friend to track with")
                FeatureRow(icon: "square.grid.2x2.fill", title: "Widget on home screen", subtitle: "Beautiful stats at a glance")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Continue") {
                withAnimation { currentPage = 2 }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }

    private var usernamePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Choose your username")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("This is how your friend will find you")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))

            TextField("", text: $username, prompt: Text("username").foregroundStyle(.white.opacity(0.3)))
                .textFieldStyle(GlassTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isUsernameFocused)
                .padding(.horizontal, 32)

            Spacer()

            Button("Continue") {
                let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
                guard name.count >= 3 else { return }
                pendingUsername = name
                store.createUser(username: name)
                withAnimation { currentPage = 3 }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
            .opacity(username.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 ? 1 : 0.5)
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .onAppear { isUsernameFocused = true }
    }

    private var invitePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Add your person")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Share your code or enter theirs.\nYou can skip and do this later.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))

            VStack(spacing: 6) {
                Text("YOUR CODE")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.4))
                Text(store.currentUser?.inviteCode ?? "------")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(6)
            }
            .padding()
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

            TextField("", text: $inviteCodeInput, prompt: Text("Friend's invite code").foregroundStyle(.white.opacity(0.3)))
                .textFieldStyle(GlassTextFieldStyle())
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(.horizontal, 32)

            if let friendError {
                Text(friendError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            VStack(spacing: 12) {
                if inviteCodeInput.count >= 6 {
                    Button {
                        Task { await connectFriend() }
                    } label: {
                        if isConnectingFriend {
                            ProgressView().tint(.white)
                        } else {
                            Text("Connect Friend")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isConnectingFriend)
                }

                Button("Skip for now") {
                    finishOnboarding()
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }

    private func finishOnboarding() {
        store.finishSetup()
        Task {
            if let user = store.currentUser {
                try? await cloudKit.publishUser(user)
            }
        }
    }

    private func connectFriend() async {
        guard let user = store.currentUser else { return }
        isConnectingFriend = true
        friendError = nil
        defer { isConnectingFriend = false }

        do {
            let updated = try await cloudKit.connectWithFriend(
                inviteCode: inviteCodeInput.uppercased(),
                currentUser: user
            )
            store.setFriend(friendID: updated.friendID!, friendUsername: updated.friendUsername!)
            store.saveUser(updated)
            store.finishSetup()
        } catch {
            friendError = error.localizedDescription
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
    }
}
