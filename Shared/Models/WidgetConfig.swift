import SwiftUI

// MARK: - Layout Style

enum WidgetLayoutStyle: String, CaseIterable, Codable, Identifiable {
    case glass
    case card
    case neon
    case mesh
    case outline
    case flat

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .glass: return "Glass"
        case .card: return "Card"
        case .neon: return "Neon Glow"
        case .mesh: return "Mesh"
        case .outline: return "Outline"
        case .flat: return "Flat"
        }
    }

    var icon: String {
        switch self {
        case .glass: return "rectangle.on.rectangle.angled"
        case .card: return "square.stack.3d.up.fill"
        case .neon: return "sparkles"
        case .mesh: return "circle.hexagongrid.fill"
        case .outline: return "square.dashed"
        case .flat: return "square.fill"
        }
    }
}

// MARK: - Accent Presets

enum WidgetAccentPreset: String, CaseIterable, Codable, Identifiable {
    case auto
    case cyan
    case purple
    case pink
    case gold
    case mint
    case coral
    case ice
    case lime
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Theme Default"
        default: return rawValue.capitalized
        }
    }

    var color: Color {
        switch self {
        case .auto: return .clear
        case .cyan: return Color(red: 0.35, green: 0.88, blue: 0.98)
        case .purple: return Color(red: 0.62, green: 0.38, blue: 0.98)
        case .pink: return Color(red: 0.98, green: 0.42, blue: 0.72)
        case .gold: return Color(red: 0.98, green: 0.78, blue: 0.28)
        case .mint: return Color(red: 0.42, green: 0.95, blue: 0.78)
        case .coral: return Color(red: 0.98, green: 0.48, blue: 0.42)
        case .ice: return Color(red: 0.75, green: 0.88, blue: 0.98)
        case .lime: return Color(red: 0.72, green: 0.98, blue: 0.35)
        case .custom: return .white
        }
    }
}

// MARK: - Widget Config

struct WidgetConfig: Codable, Equatable {
    var theme: WidgetTheme
    var layout: WidgetLayoutStyle
    var accentPreset: WidgetAccentPreset
    var customAccentRed: Double
    var customAccentGreen: Double
    var customAccentBlue: Double

    static let `default` = WidgetConfig(
        theme: .aurora,
        layout: .glass,
        accentPreset: .auto,
        customAccentRed: 0.55,
        customAccentGreen: 0.35,
        customAccentBlue: 0.95
    )

    func resolvedAccent(fallback: Color) -> Color {
        switch accentPreset {
        case .auto: return fallback
        case .custom:
            return Color(red: customAccentRed, green: customAccentGreen, blue: customAccentBlue)
        default:
            return accentPreset.color
        }
    }
}

enum WidgetConfigLoader {
    static func load() -> WidgetConfig {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        guard let data = defaults?.data(forKey: AppConstants.UserDefaultsKeys.widgetConfigJSON),
              let config = try? JSONDecoder().decode(WidgetConfig.self, from: data) else {
            return legacyLoad()
        }
        return config
    }

    static func save(_ config: WidgetConfig) {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        if let data = try? JSONEncoder().encode(config) {
            defaults?.set(data, forKey: AppConstants.UserDefaultsKeys.widgetConfigJSON)
        }
        defaults?.set(config.theme.rawValue, forKey: AppConstants.UserDefaultsKeys.widgetTheme)
    }

    private static func legacyLoad() -> WidgetConfig {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        let themeRaw = defaults?.string(forKey: AppConstants.UserDefaultsKeys.widgetTheme) ?? WidgetTheme.aurora.rawValue
        let theme = WidgetTheme(rawValue: themeRaw) ?? .aurora
        return WidgetConfig(theme: theme, layout: .glass, accentPreset: .auto,
                            customAccentRed: 0.55, customAccentGreen: 0.35, customAccentBlue: 0.95)
    }
}
