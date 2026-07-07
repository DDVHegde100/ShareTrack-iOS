import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private init() {}

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func notifyNewShare(from sender: String, platform: SocialPlatform) {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        guard defaults?.bool(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled) != false else { return }

        let content = UNMutableNotificationContent()
        content.title = "New video from \(sender)"
        content.body = "You got a \(platform.displayName) share — open ShareTrack to view!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func notifyShareLogged(platform: SocialPlatform, points: Int) {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        guard defaults?.bool(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled) != false else { return }

        let content = UNMutableNotificationContent()
        content.title = "Share tracked!"
        content.body = "\(platform.displayName) video logged. +\(points) points"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func notifyNewMessage(from sender: String) {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        guard defaults?.bool(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled) != false else { return }

        let content = UNMutableNotificationContent()
        content.title = "Message from \(sender)"
        content.body = "Open ShareTrack to reply"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
