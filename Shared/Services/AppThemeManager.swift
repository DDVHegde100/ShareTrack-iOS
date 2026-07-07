import SwiftUI

struct AppTheme: Equatable {
    let widgetTheme: WidgetTheme
    let accent: Color

    var background: LinearGradient { widgetTheme.backgroundGradient }
    var primaryText: Color { widgetTheme.primaryTextColor }
    var secondaryText: Color { widgetTheme.secondaryTextColor }
    var cardBackground: Color {
        widgetTheme.isLightTheme ? Color.black.opacity(0.04) : Color.white.opacity(0.06)
    }
    var glassFill: Color {
        widgetTheme.isLightTheme ? Color.white.opacity(0.65) : Color.white.opacity(0.10)
    }

    static let `default` = AppTheme(widgetTheme: .aurora, accent: WidgetTheme.aurora.accentColor)
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.default
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

@MainActor
final class AppThemeManager: ObservableObject {
    static let shared = AppThemeManager()

    @Published var matchWidgetTheme: Bool = true
    @Published var appThemeOverride: WidgetTheme = .aurora
    @Published private(set) var currentTheme: AppTheme = .default

    private init() {
        let defaults = UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)
        matchWidgetTheme = defaults?.object(forKey: AppConstants.UserDefaultsKeys.matchWidgetTheme) as? Bool ?? true
        if let raw = defaults?.string(forKey: AppConstants.UserDefaultsKeys.appThemeOverride),
           let theme = WidgetTheme(rawValue: raw) {
            appThemeOverride = theme
        }
        refresh()
    }

    func refresh(widgetConfig: WidgetConfig? = nil) {
        let config = widgetConfig ?? WidgetConfigLoader.load()
        let theme = matchWidgetTheme ? config.theme : appThemeOverride
        let accent = config.resolvedAccent(fallback: theme.accentColor)
        currentTheme = AppTheme(widgetTheme: theme, accent: accent)
    }

    func setMatchWidget(_ match: Bool) {
        matchWidgetTheme = match
        UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)?
            .set(match, forKey: AppConstants.UserDefaultsKeys.matchWidgetTheme)
        refresh()
    }

    func setAppThemeOverride(_ theme: WidgetTheme) {
        appThemeOverride = theme
        UserDefaults(suiteName: AppConstants.sharedDefaultsSuite)?
            .set(theme.rawValue, forKey: AppConstants.UserDefaultsKeys.appThemeOverride)
        refresh()
    }
}

struct ThemedScreenBackground: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        theme.background.ignoresSafeArea()
    }
}

struct ThemedCard: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.glassFill.opacity(0.5), lineWidth: 0.5)
            )
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCard())
    }
}

private extension AppTheme {
    var glassFill: Color {
        widgetTheme.isLightTheme ? Color.white.opacity(0.5) : Color.white.opacity(0.12)
    }
}
