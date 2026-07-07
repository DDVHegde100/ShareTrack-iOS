import Foundation
import CloudKit

enum PlatformURLDetector {
    static func detectPlatform(from url: URL) -> SocialPlatform {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()

        if host.contains("instagram") || host.contains("instagr.am") { return .instagram }
        if host.contains("tiktok") || host.contains("vm.tiktok") { return .tiktok }
        if host.contains("discord") || host.contains("discordapp") { return .discord }
        if host.contains("snapchat") { return .snapchat }
        if host.contains("youtube") || host.contains("youtu.be") { return .youtube }
        if path.contains("tiktok") { return .tiktok }
        return .instagram
    }

    static func isSocialMediaURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("instagram") || host.contains("instagr.am")
            || host.contains("tiktok") || host.contains("vm.tiktok")
            || host.contains("discord") || host.contains("discordapp")
            || host.contains("snapchat")
            || host.contains("youtube") || host.contains("youtu.be")
    }

    static func extractURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme?.hasPrefix("http") == true {
            return url
        }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return detector?.firstMatch(in: trimmed, range: range)?.url
    }
}

enum ShareEventManager {
    static func loadEvents() -> [ShareEvent] {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        guard let data = defaults?.data(forKey: "shareEvents"),
              let events = try? JSONDecoder().decode([ShareEvent].self, from: data) else {
            return []
        }
        return events
    }

    static func loadUser() -> UserProfile? {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        guard let data = defaults?.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return user
    }

    static func saveEvents(_ events: [ShareEvent]) {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        if let data = try? JSONEncoder().encode(events) {
            defaults?.set(data, forKey: "shareEvents")
        }
    }

    static func saveUser(_ user: UserProfile) {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        if let data = try? JSONEncoder().encode(user) {
            defaults?.set(data, forKey: "currentUser")
        }
    }

    static func isDuplicate(url: String?, platform: SocialPlatform, events: [ShareEvent], within seconds: TimeInterval = 60) -> Bool {
        guard let url else { return false }
        let cutoff = Date().addingTimeInterval(-seconds)
        return events.contains {
            $0.contentURL == url && $0.platform == platform && $0.sharedAt > cutoff
        }
    }

    @discardableResult
    static func logShare(
        platform: SocialPlatform,
        contentURL: String? = nil,
        senderID: String? = nil,
        receiverID: String? = nil
    ) -> ShareEvent? {
        guard let user = loadUser() else { return nil }
        let friendID = receiverID ?? user.friendID
        guard let friendID else { return nil }

        var events = loadEvents()
        if isDuplicate(url: contentURL, platform: platform, events: events) {
            return nil
        }

        let event = ShareEvent(
            senderID: senderID ?? user.id,
            receiverID: friendID,
            platform: platform,
            contentURL: contentURL
        )

        events.append(event)
        saveEvents(events)

        var updatedUser = user
        updatedUser.totalPoints += event.pointsEarned
        saveUser(updatedUser)

        refreshCachedStats(userID: user.id, totalPoints: updatedUser.totalPoints, events: events)

        Task {
            await CloudKitUploader.upload(event)
        }

        return event
    }

    static func refreshCachedStats(userID: String, totalPoints: Int, events: [ShareEvent]) {
        let stats = StatsCalculator.calculate(events: events, currentUserID: userID, totalPoints: totalPoints)
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        if let data = try? JSONEncoder().encode(stats) {
            defaults?.set(data, forKey: AppConstants.UserDefaultsKeys.cachedStatsJSON)
        }
        defaults?.set(Date(), forKey: AppConstants.UserDefaultsKeys.lastStatsUpdate)
    }
}

enum CloudKitUploader {
    static func upload(_ event: ShareEvent) async {
        let container = CKContainer(identifier: AppConstants.cloudKitContainerID)
        let db = container.publicCloudDatabase

        let record = CKRecord(
            recordType: AppConstants.RecordTypes.shareEvent,
            recordID: CKRecord.ID(recordName: event.id)
        )
        record["senderID"] = event.senderID as CKRecordValue
        record["receiverID"] = event.receiverID as CKRecordValue
        record["platform"] = event.platform.rawValue as CKRecordValue
        record["sharedAt"] = event.sharedAt as CKRecordValue
        record["isViewed"] = (event.isViewed ? 1 : 0) as CKRecordValue
        record["contentURL"] = event.contentURL as CKRecordValue?
        record["pointsEarned"] = event.pointsEarned as CKRecordValue

        try? await db.save(record)
    }
}
