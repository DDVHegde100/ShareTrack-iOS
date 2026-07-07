import Foundation
import WidgetKit

@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var syncError: String?

    private init() {}

    func syncIfNeeded(store: SharedDataStore, cloudKit: CloudKitService) async {
        guard store.hasCompletedOnboarding, let user = store.currentUser else { return }

        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        let lastLocal = defaults?.object(forKey: AppConstants.UserDefaultsKeys.lastStatsUpdate) as? Date
        let shouldSync = lastLocal == nil || Date().timeIntervalSince(lastLocal!) > 300

        guard shouldSync else { return }
        await performSync(store: store, cloudKit: cloudKit)
    }

    func performSync(store: SharedDataStore, cloudKit: CloudKitService) async {
        guard let user = store.currentUser else { return }
        isSyncing = true
        syncError = nil

        do {
            let previousIDs = Set(store.shareEvents.map(\.id))
            let previousMsgIDs = Set(MessageService.shared.messages.map(\.id))
            let payload = try await cloudKit.syncAll(user: user)
            store.importEvents(payload.events)
            MessageService.shared.importMessages(payload.messages)
            MessageService.shared.importComments(payload.comments)
            lastSyncDate = Date()

            let newReceived = payload.events.filter {
                $0.receiverID == user.id && !previousIDs.contains($0.id) && !$0.isViewed
            }
            for event in newReceived {
                NotificationService.shared.notifyNewShare(
                    from: user.friendUsername ?? "Friend",
                    platform: event.platform
                )
            }

            let newMessages = payload.messages.filter {
                $0.receiverID == user.id && !previousMsgIDs.contains($0.id)
            }
            for msg in newMessages {
                NotificationService.shared.notifyNewMessage(from: user.friendUsername ?? "Friend")
            }
        } catch {
            syncError = error.localizedDescription
        }

        isSyncing = false
        store.syncWidgetData()
    }
}
