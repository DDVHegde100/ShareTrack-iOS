import Foundation
import CloudKit

enum CloudKitError: LocalizedError {
    case notAuthenticated
    case recordNotFound
    case friendNotFound
    case alreadyHasFriend
    case invalidInviteCode
    case cloudKitUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to iCloud to sync with your friend."
        case .recordNotFound: return "User record not found."
        case .friendNotFound: return "No user found with that invite code."
        case .alreadyHasFriend: return "You can only have one friend connected at a time."
        case .invalidInviteCode: return "Invalid invite code. Check and try again."
        case .cloudKitUnavailable(let msg): return "CloudKit error: \(msg)"
        }
    }
}

@MainActor
final class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    private let container: CKContainer
    private let publicDB: CKDatabase
    private let privateDB: CKDatabase

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    private init() {
        container = CKContainer(identifier: AppConstants.cloudKitContainerID)
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }

    func checkAccountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    func publishUser(_ user: UserProfile) async throws {
        let record = CKRecord(recordType: AppConstants.RecordTypes.user, recordID: CKRecord.ID(recordName: user.id))
        record["username"] = user.username as CKRecordValue
        record["inviteCode"] = user.inviteCode as CKRecordValue
        record["friendID"] = user.friendID as CKRecordValue?
        record["totalPoints"] = user.totalPoints as CKRecordValue
        record["connectedPlatformsJSON"] = encodePlatforms(user.connectedPlatforms) as CKRecordValue?
        record["createdAt"] = user.createdAt as CKRecordValue

        _ = try await publicDB.save(record)
    }

    func findUserByInviteCode(_ code: String) async throws -> UserProfile {
        let predicate = NSPredicate(format: "inviteCode == %@", code.uppercased())
        let query = CKQuery(recordType: AppConstants.RecordTypes.user, predicate: predicate)

        let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)
        guard let (_, result) = results.first,
              case .success(let record) = result else {
            throw CloudKitError.friendNotFound
        }
        return userFromRecord(record)
    }

    func connectWithFriend(inviteCode: String, currentUser: UserProfile) async throws -> UserProfile {
        guard !currentUser.hasFriend else { throw CloudKitError.alreadyHasFriend }

        let friend = try await findUserByInviteCode(inviteCode.uppercased())
        guard friend.id != currentUser.id else { throw CloudKitError.invalidInviteCode }

        var updatedUser = currentUser
        updatedUser.friendID = friend.id
        updatedUser.friendUsername = friend.username

        var updatedFriend = friend
        if updatedFriend.friendID == nil {
            updatedFriend.friendID = currentUser.id
            updatedFriend.friendUsername = currentUser.username
            try await publishUser(updatedFriend)
        }

        try await publishUser(updatedUser)

        let friendship = CKRecord(recordType: AppConstants.RecordTypes.friendship)
        friendship["userA"] = currentUser.id as CKRecordValue
        friendship["userB"] = friend.id as CKRecordValue
        friendship["connectedAt"] = Date() as CKRecordValue
        _ = try await publicDB.save(friendship)

        return updatedUser
    }

    func uploadShareEvent(_ event: ShareEvent) async throws {
        let record = CKRecord(recordType: AppConstants.RecordTypes.shareEvent, recordID: CKRecord.ID(recordName: event.id))
        record["senderID"] = event.senderID as CKRecordValue
        record["receiverID"] = event.receiverID as CKRecordValue
        record["platform"] = event.platform.rawValue as CKRecordValue
        record["sharedAt"] = event.sharedAt as CKRecordValue
        record["isViewed"] = (event.isViewed ? 1 : 0) as CKRecordValue
        record["contentURL"] = event.contentURL as CKRecordValue?
        record["pointsEarned"] = event.pointsEarned as CKRecordValue

        _ = try await publicDB.save(record)
    }

    func fetchShareEvents(for userID: String, friendID: String?) async throws -> [ShareEvent] {
        var allEvents: [ShareEvent] = []

        let sentPredicate = NSPredicate(format: "senderID == %@", userID)
        let sentQuery = CKQuery(recordType: AppConstants.RecordTypes.shareEvent, predicate: sentPredicate)
        sentQuery.sortDescriptors = [NSSortDescriptor(key: "sharedAt", ascending: false)]

        let (sentResults, _) = try await publicDB.records(matching: sentQuery, resultsLimit: 200)
        for (_, result) in sentResults {
            if case .success(let record) = result {
                allEvents.append(shareEventFromRecord(record))
            }
        }

        if let friendID {
            let receivedPredicate = NSPredicate(format: "senderID == %@ AND receiverID == %@", friendID, userID)
            let receivedQuery = CKQuery(recordType: AppConstants.RecordTypes.shareEvent, predicate: receivedPredicate)
            receivedQuery.sortDescriptors = [NSSortDescriptor(key: "sharedAt", ascending: false)]

            let (receivedResults, _) = try await publicDB.records(matching: receivedQuery, resultsLimit: 200)
            for (_, result) in receivedResults {
                if case .success(let record) = result {
                    let event = shareEventFromRecord(record)
                    if !allEvents.contains(where: { $0.id == event.id }) {
                        allEvents.append(event)
                    }
                }
            }
        }

        return allEvents.sorted { $0.sharedAt > $1.sharedAt }
    }

    func syncAll(user: UserProfile) async throws -> [ShareEvent] {
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        try await publishUser(user)
        let events = try await fetchShareEvents(for: user.id, friendID: user.friendID)
        lastSyncDate = Date()
        return events
    }

    func markEventViewedInCloud(_ eventID: String) async throws {
        let recordID = CKRecord.ID(recordName: eventID)
        let record = try await publicDB.record(for: recordID)
        record["isViewed"] = 1 as CKRecordValue
        _ = try await publicDB.save(record)
    }

    private func userFromRecord(_ record: CKRecord) -> UserProfile {
        UserProfile(
            id: record.recordID.recordName,
            username: record["username"] as? String ?? "Unknown",
            inviteCode: record["inviteCode"] as? String ?? "",
            connectedPlatforms: decodePlatforms(record["connectedPlatformsJSON"] as? String),
            friendID: record["friendID"] as? String,
            friendUsername: nil,
            totalPoints: record["totalPoints"] as? Int ?? 0,
            createdAt: record["createdAt"] as? Date ?? Date()
        )
    }

    private func shareEventFromRecord(_ record: CKRecord) -> ShareEvent {
        ShareEvent(
            id: record.recordID.recordName,
            senderID: record["senderID"] as? String ?? "",
            receiverID: record["receiverID"] as? String ?? "",
            platform: SocialPlatform(rawValue: record["platform"] as? String ?? "") ?? .instagram,
            sharedAt: record["sharedAt"] as? Date ?? Date(),
            isViewed: (record["isViewed"] as? Int ?? 0) == 1,
            contentURL: record["contentURL"] as? String,
            pointsEarned: record["pointsEarned"] as? Int ?? 10
        )
    }

    private func encodePlatforms(_ platforms: [PlatformConnection]) -> String {
        guard let data = try? JSONEncoder().encode(platforms),
              let str = String(data: data, encoding: .utf8) else { return "[]" }
        return str
    }

    private func decodePlatforms(_ json: String?) -> [PlatformConnection] {
        guard let json, let data = json.data(using: .utf8),
              let platforms = try? JSONDecoder().decode([PlatformConnection].self, from: data) else {
            return []
        }
        return platforms
    }
}
