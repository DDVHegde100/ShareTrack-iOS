import SwiftUI

enum ContentCategory: String, CaseIterable, Codable, Identifiable {
    case funny
    case music
    case cute
    case sports
    case food
    case dance
    case news
    case tutorial
    case aesthetic
    case gaming
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .funny: return "Funny"
        case .music: return "Music"
        case .cute: return "Cute"
        case .sports: return "Sports"
        case .food: return "Food"
        case .dance: return "Dance"
        case .news: return "News"
        case .tutorial: return "Tutorial"
        case .aesthetic: return "Aesthetic"
        case .gaming: return "Gaming"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .funny: return "face.smiling.fill"
        case .music: return "music.note"
        case .cute: return "heart.fill"
        case .sports: return "sportscourt.fill"
        case .food: return "fork.knife"
        case .dance: return "figure.dance"
        case .news: return "newspaper.fill"
        case .tutorial: return "lightbulb.fill"
        case .aesthetic: return "sparkles"
        case .gaming: return "gamecontroller.fill"
        case .other: return "tag.fill"
        }
    }

    var color: Color {
        switch self {
        case .funny: return .yellow
        case .music: return .purple
        case .cute: return .pink
        case .sports: return .green
        case .food: return .orange
        case .dance: return .cyan
        case .news: return .blue
        case .tutorial: return .mint
        case .aesthetic: return Color(red: 0.85, green: 0.55, blue: 0.95)
        case .gaming: return Color(red: 0.55, green: 0.35, blue: 0.95)
        case .other: return .gray
        }
    }

    var bonusPoints: Int {
        switch self {
        case .funny, .cute: return 2
        case .tutorial, .news: return 3
        default: return 1
        }
    }
}

enum ShareReaction: String, CaseIterable, Codable, Identifiable {
    case heart
    case fire
    case laugh
    case wow
    case thumbsUp

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .heart: return "❤️"
        case .fire: return "🔥"
        case .laugh: return "😂"
        case .wow: return "😮"
        case .thumbsUp: return "👍"
        }
    }

    var icon: String {
        switch self {
        case .heart: return "heart.fill"
        case .fire: return "flame.fill"
        case .laugh: return "face.smiling.fill"
        case .wow: return "exclamationmark.circle.fill"
        case .thumbsUp: return "hand.thumbsup.fill"
        }
    }
}
