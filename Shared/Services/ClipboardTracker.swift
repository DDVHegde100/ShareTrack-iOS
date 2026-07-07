import Foundation
import UIKit

@MainActor
final class ClipboardTracker: ObservableObject {
    static let shared = ClipboardTracker()

    @Published var pendingURL: URL?
    @Published var pendingPlatform: SocialPlatform?
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)?
                .set(isEnabled, forKey: AppConstants.UserDefaultsKeys.clipboardTrackingEnabled)
        }
    }

    private var lastCheckedString: String?

    private init() {
        isEnabled = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)?
            .object(forKey: AppConstants.UserDefaultsKeys.clipboardTrackingEnabled) as? Bool ?? true
    }

    func checkClipboard() {
        guard isEnabled else {
            pendingURL = nil
            pendingPlatform = nil
            return
        }

        guard UIPasteboard.general.hasURLs || UIPasteboard.general.hasStrings else {
            pendingURL = nil
            pendingPlatform = nil
            return
        }

        var foundURL: URL?

        if let urls = UIPasteboard.general.urls, let first = urls.first {
            foundURL = first
        } else if let string = UIPasteboard.general.string {
            foundURL = PlatformURLDetector.extractURL(from: string)
        }

        guard let url = foundURL, PlatformURLDetector.isSocialMediaURL(url) else {
            pendingURL = nil
            pendingPlatform = nil
            return
        }

        let urlString = url.absoluteString
        if urlString == lastCheckedString { return }

        lastCheckedString = urlString
        pendingURL = url
        pendingPlatform = PlatformURLDetector.detectPlatform(from: url)
    }

    func trackPendingShare(store: SharedDataStore) {
        guard let url = pendingURL, let platform = pendingPlatform else { return }
        guard store.currentUser?.friendID != nil else { return }

        if let event = ShareEventManager.logShare(platform: platform, contentURL: url.absoluteString) {
            store.loadFromDisk()
            NotificationService.shared.notifyShareLogged(platform: platform, points: event.pointsEarned)
        }

        pendingURL = nil
        pendingPlatform = nil
        lastCheckedString = url.absoluteString
    }

    func dismissPending() {
        pendingURL = nil
        pendingPlatform = nil
    }
}
