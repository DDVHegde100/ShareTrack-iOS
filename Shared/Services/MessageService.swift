import Foundation
import CloudKit

enum MessageStore {
    static func load() -> [ChatMessage] {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        guard let data = defaults?.data(forKey: AppConstants.UserDefaultsKeys.messagesJSON),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return []
        }
        return messages.sorted { $0.sentAt < $1.sentAt }
    }

    static func save(_ messages: [ChatMessage]) {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        if let data = try? JSONEncoder().encode(messages) {
            defaults?.set(data, forKey: AppConstants.UserDefaultsKeys.messagesJSON)
        }
    }

    static func loadComments() -> [ShareComment] {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        guard let data = defaults?.data(forKey: AppConstants.UserDefaultsKeys.commentsJSON),
              let comments = try? JSONDecoder().decode([ShareComment].self, from: data) else {
            return []
        }
        return comments
    }

    static func saveComments(_ comments: [ShareComment]) {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        if let data = try? JSONEncoder().encode(comments) {
            defaults?.set(data, forKey: AppConstants.UserDefaultsKeys.commentsJSON)
        }
    }
}

@MainActor
final class MessageService: ObservableObject {
    static let shared = MessageService()

    @Published var messages: [ChatMessage] = []
    @Published var comments: [ShareComment] = []

    private init() {
        messages = MessageStore.load()
        comments = MessageStore.loadComments()
    }

    var unreadCount: Int {
        guard let userID = ShareEventManager.loadUser()?.id else { return 0 }
        return messages.filter { $0.receiverID == userID && !$0.isRead }.count
    }

    func sendMessage(text: String, shareEventID: String? = nil) async throws {
        guard let user = ShareEventManager.loadUser(),
              let friendID = user.friendID,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = ChatMessage(
            senderID: user.id,
            receiverID: friendID,
            text: text,
            shareEventID: shareEventID
        )
        messages.append(message)
        MessageStore.save(messages)

        try await CloudKitService.shared.uploadMessage(message)
    }

    func addComment(shareEventID: String, text: String) async throws {
        guard let user = ShareEventManager.loadUser(),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let comment = ShareComment(shareEventID: shareEventID, authorID: user.id, text: text)
        comments.append(comment)
        MessageStore.saveComments(comments)
        try await CloudKitService.shared.uploadComment(comment)
    }

    func comments(for shareEventID: String) -> [ShareComment] {
        comments.filter { $0.shareEventID == shareEventID }.sorted { $0.createdAt < $1.createdAt }
    }

    func markMessagesRead(currentUserID: String) {
        var updated = messages
        for i in updated.indices where updated[i].receiverID == currentUserID {
            updated[i].isRead = true
        }
        messages = updated
        MessageStore.save(messages)
    }

    func importMessages(_ incoming: [ChatMessage]) {
        var merged = messages
        for msg in incoming where !merged.contains(where: { $0.id == msg.id }) {
            merged.append(msg)
        }
        messages = merged.sorted { $0.sentAt < $1.sentAt }
        MessageStore.save(messages)
    }

    func importComments(_ incoming: [ShareComment]) {
        var merged = comments
        for c in incoming where !merged.contains(where: { $0.id == c.id }) {
            merged.append(c)
        }
        comments = merged
        MessageStore.saveComments(comments)
    }
}
