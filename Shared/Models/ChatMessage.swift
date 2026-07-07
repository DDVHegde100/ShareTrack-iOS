import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    let senderID: String
    let receiverID: String
    let text: String
    let sentAt: Date
    var shareEventID: String?
    var isRead: Bool

    init(
        id: String = UUID().uuidString,
        senderID: String,
        receiverID: String,
        text: String,
        sentAt: Date = Date(),
        shareEventID: String? = nil,
        isRead: Bool = false
    ) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sentAt = sentAt
        self.shareEventID = shareEventID
        self.isRead = isRead
    }
}

struct ShareComment: Codable, Identifiable, Equatable {
    let id: String
    let shareEventID: String
    let authorID: String
    let text: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        shareEventID: String,
        authorID: String,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.shareEventID = shareEventID
        self.authorID = authorID
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }
}
