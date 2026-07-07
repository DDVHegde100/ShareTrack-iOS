import SwiftUI

enum WidgetTheme: String, CaseIterable, Codable, Identifiable {
    case aurora
    case midnight
    case sunset
    case pastel
    case neon
    case minimal
    case ocean
    case roseGold
    case ember
    case forest
    case lavender
    case cosmic
    case slate
    case cherry
    case mintFrost
    case goldenHour
    case glassWhite
    case glassDark
    case iridescent
    case monochrome
    case sakura
    case deepSpace

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mintFrost: return "Mint Frost"
        case .goldenHour: return "Golden Hour"
        case .glassWhite: return "Glass White"
        case .glassDark: return "Glass Dark"
        case .roseGold: return "Rose Gold"
        case .deepSpace: return "Deep Space"
        default: return rawValue.capitalized
        }
    }

    var isLightTheme: Bool {
        switch self {
        case .pastel, .minimal, .glassWhite, .mintFrost, .goldenHour, .sakura:
            return true
        default:
            return false
        }
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var gradientColors: [Color] {
        switch self {
        case .aurora:
            return [Color(red: 0.06, green: 0.08, blue: 0.18), Color(red: 0.14, green: 0.10, blue: 0.30), Color(red: 0.08, green: 0.22, blue: 0.32)]
        case .midnight:
            return [Color(red: 0.04, green: 0.04, blue: 0.10), Color(red: 0.10, green: 0.08, blue: 0.20)]
        case .sunset:
            return [Color(red: 0.98, green: 0.42, blue: 0.32), Color(red: 0.82, green: 0.22, blue: 0.52), Color(red: 0.42, green: 0.16, blue: 0.62)]
        case .pastel:
            return [Color(red: 0.96, green: 0.84, blue: 0.96), Color(red: 0.84, green: 0.92, blue: 0.98), Color(red: 0.92, green: 0.96, blue: 0.86)]
        case .neon:
            return [Color(red: 0.04, green: 0.02, blue: 0.12), Color(red: 0.10, green: 0.02, blue: 0.22)]
        case .minimal:
            return [Color(white: 0.98), Color(white: 0.92)]
        case .ocean:
            return [Color(red: 0.04, green: 0.18, blue: 0.32), Color(red: 0.08, green: 0.32, blue: 0.48), Color(red: 0.12, green: 0.42, blue: 0.55)]
        case .roseGold:
            return [Color(red: 0.28, green: 0.14, blue: 0.18), Color(red: 0.55, green: 0.28, blue: 0.32), Color(red: 0.85, green: 0.55, blue: 0.48)]
        case .ember:
            return [Color(red: 0.18, green: 0.06, blue: 0.04), Color(red: 0.45, green: 0.12, blue: 0.06), Color(red: 0.72, green: 0.28, blue: 0.08)]
        case .forest:
            return [Color(red: 0.05, green: 0.12, blue: 0.08), Color(red: 0.10, green: 0.24, blue: 0.14), Color(red: 0.16, green: 0.32, blue: 0.18)]
        case .lavender:
            return [Color(red: 0.22, green: 0.16, blue: 0.38), Color(red: 0.38, green: 0.28, blue: 0.58), Color(red: 0.52, green: 0.38, blue: 0.72)]
        case .cosmic:
            return [Color(red: 0.08, green: 0.02, blue: 0.18), Color(red: 0.18, green: 0.04, blue: 0.35), Color(red: 0.05, green: 0.08, blue: 0.28)]
        case .slate:
            return [Color(red: 0.12, green: 0.14, blue: 0.18), Color(red: 0.22, green: 0.24, blue: 0.28), Color(red: 0.16, green: 0.18, blue: 0.22)]
        case .cherry:
            return [Color(red: 0.22, green: 0.04, blue: 0.10), Color(red: 0.55, green: 0.08, blue: 0.22), Color(red: 0.78, green: 0.18, blue: 0.32)]
        case .mintFrost:
            return [Color(red: 0.88, green: 0.96, blue: 0.94), Color(red: 0.78, green: 0.92, blue: 0.96), Color(red: 0.92, green: 0.98, blue: 0.95)]
        case .goldenHour:
            return [Color(red: 0.98, green: 0.92, blue: 0.82), Color(red: 0.96, green: 0.82, blue: 0.62), Color(red: 0.92, green: 0.72, blue: 0.48)]
        case .glassWhite:
            return [Color(red: 0.96, green: 0.96, blue: 0.98), Color(red: 0.90, green: 0.92, blue: 0.96), Color(red: 0.94, green: 0.94, blue: 0.98)]
        case .glassDark:
            return [Color(red: 0.10, green: 0.10, blue: 0.14), Color(red: 0.16, green: 0.16, blue: 0.22), Color(red: 0.12, green: 0.14, blue: 0.20)]
        case .iridescent:
            return [Color(red: 0.15, green: 0.10, blue: 0.28), Color(red: 0.28, green: 0.15, blue: 0.38), Color(red: 0.12, green: 0.25, blue: 0.35)]
        case .monochrome:
            return [Color(white: 0.08), Color(white: 0.14), Color(white: 0.10)]
        case .sakura:
            return [Color(red: 0.98, green: 0.90, blue: 0.94), Color(red: 0.96, green: 0.82, blue: 0.88), Color(red: 0.94, green: 0.88, blue: 0.96)]
        case .deepSpace:
            return [Color(red: 0.02, green: 0.02, blue: 0.06), Color(red: 0.06, green: 0.04, blue: 0.14), Color(red: 0.04, green: 0.08, blue: 0.18)]
        }
    }

    var primaryTextColor: Color {
        isLightTheme ? Color(red: 0.12, green: 0.12, blue: 0.16) : .white
    }

    var secondaryTextColor: Color {
        isLightTheme ? Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.55) : .white.opacity(0.65)
    }

    var accentColor: Color {
        switch self {
        case .aurora: return Color(red: 0.35, green: 0.88, blue: 0.98)
        case .midnight: return Color(red: 0.58, green: 0.45, blue: 0.98)
        case .sunset: return Color(red: 1.0, green: 0.82, blue: 0.45)
        case .pastel: return Color(red: 0.72, green: 0.42, blue: 0.88)
        case .neon: return Color(red: 0.0, green: 1.0, blue: 0.75)
        case .minimal: return Color(red: 0.18, green: 0.18, blue: 0.22)
        case .ocean: return Color(red: 0.35, green: 0.82, blue: 0.98)
        case .roseGold: return Color(red: 0.95, green: 0.72, blue: 0.68)
        case .ember: return Color(red: 1.0, green: 0.55, blue: 0.22)
        case .forest: return Color(red: 0.45, green: 0.88, blue: 0.55)
        case .lavender: return Color(red: 0.78, green: 0.62, blue: 0.98)
        case .cosmic: return Color(red: 0.65, green: 0.35, blue: 0.98)
        case .slate: return Color(red: 0.72, green: 0.78, blue: 0.88)
        case .cherry: return Color(red: 0.98, green: 0.45, blue: 0.58)
        case .mintFrost: return Color(red: 0.28, green: 0.72, blue: 0.62)
        case .goldenHour: return Color(red: 0.88, green: 0.55, blue: 0.18)
        case .glassWhite: return Color(red: 0.35, green: 0.45, blue: 0.95)
        case .glassDark: return Color(red: 0.55, green: 0.75, blue: 0.98)
        case .iridescent: return Color(red: 0.55, green: 0.85, blue: 0.98)
        case .monochrome: return Color(white: 0.85)
        case .sakura: return Color(red: 0.88, green: 0.35, blue: 0.55)
        case .deepSpace: return Color(red: 0.45, green: 0.65, blue: 0.98)
        }
    }

    var chartColor: Color { accentColor }

    var glowColor: Color {
        accentColor.opacity(isLightTheme ? 0.35 : 0.55)
    }
}
