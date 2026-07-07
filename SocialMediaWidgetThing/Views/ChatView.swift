import SwiftUI

struct ChatView: View {
    @EnvironmentObject var store: SharedDataStore
    @EnvironmentObject var messages: MessageService
    @Environment(\.appTheme) private var theme
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if store.currentUser?.friendID == nil {
                noFriendState
            } else {
                messageList
                inputBar
            }
        }
        .background(ThemedScreenBackground())
        .navigationTitle(store.currentUser?.friendUsername ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let id = store.currentUser?.id {
                messages.markMessagesRead(currentUserID: id)
            }
        }
    }

    private var noFriendState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(theme.secondaryText)
            Text("Connect a friend to chat")
                .font(.headline)
                .foregroundStyle(theme.primaryText)
            Text("Pair via invite code in the Friend tab")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
            Spacer()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages.messages) { msg in
                        MessageBubble(
                            message: msg,
                            isFromMe: msg.senderID == store.currentUser?.id
                        )
                        .id(msg.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.messages.count) { _, _ in
                if let last = messages.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(theme.glassFill, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(theme.primaryText)
                .focused($isFocused)

            Button {
                Task { await send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(theme.accent)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func send() async {
        let text = draft
        draft = ""
        try? await messages.sendMessage(text: text)
        store.refreshStats()
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromMe: Bool
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack {
            if isFromMe { Spacer(minLength: 48) }
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(isFromMe ? .white : theme.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isFromMe ? theme.accent : theme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )

                Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
            }
            if !isFromMe { Spacer(minLength: 48) }
        }
    }
}

private extension AppTheme {
    var glassFill: Color {
        widgetTheme.isLightTheme ? Color.white.opacity(0.55) : Color.white.opacity(0.10)
    }
}
