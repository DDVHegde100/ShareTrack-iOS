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
            let events = try await cloudKit.syncAll(user: user)
            store.importEvents(events)
            lastSyncDate = Date()

            let newReceived = events.filter {
                $0.receiverID == user.id && !previousIDs.contains($0.id) && !$0.isViewed
            }
            for event in newReceived {
                NotificationService.shared.notifyNewShare(
                    from: user.friendUsername ?? "Friend",
                    platform: event.platform
                )
            }
        } catch {
            syncError = error.localizedDescription
        }

        isSyncing = false
        store.syncWidgetData()
    }
}
