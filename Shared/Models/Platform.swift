import SwiftUI

enum SocialPlatform: String, CaseIterable, Codable, Identifiable {
    case instagram
    case tiktok
    case discord
    case snapchat
    case youtube

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .discord: return "Discord"
        case .snapchat: return "Snapchat"
        case .youtube: return "YouTube"
        }
    }

    var iconName: String {
        switch self {
        case .instagram: return "camera.circle.fill"
        case .tiktok: return "music.note.list"
        case .discord: return "bubble.left.and.bubble.right.fill"
        case .snapchat: return "bolt.circle.fill"
        case .youtube: return "play.rectangle.fill"
        }
    }

    var brandColor: Color {
        switch self {
        case .instagram: return Color(red: 0.88, green: 0.19, blue: 0.42)
        case .tiktok: return Color(red: 0.0, green: 0.96, blue: 0.88)
        case .discord: return Color(red: 0.34, green: 0.40, blue: 0.95)
        case .snapchat: return Color(red: 1.0, green: 0.99, blue: 0.0)
        case .youtube: return Color(red: 1.0, green: 0.0, blue: 0.0)
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .instagram:
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.55, blue: 0.24),
                    Color(red: 0.91, green: 0.27, blue: 0.38),
                    Color(red: 0.59, green: 0.22, blue: 0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .tiktok:
            return LinearGradient(
                colors: [Color.black, Color(red: 0.0, green: 0.96, blue: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .discord:
            return LinearGradient(
                colors: [Color(red: 0.34, green: 0.40, blue: 0.95), Color(red: 0.55, green: 0.35, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .snapchat:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.99, blue: 0.0), Color(red: 1.0, green: 0.85, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .youtube:
            return LinearGradient(
                colors: [Color.red, Color(red: 0.8, green: 0.0, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Points awarded per share on this platform
    var pointsPerShare: Int {
        switch self {
        case .instagram: return 10
        case .tiktok: return 12
        case .discord: return 8
        case .snapchat: return 15
        case .youtube: return 10
        }
    }
}
