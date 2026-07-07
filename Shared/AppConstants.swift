import Foundation

enum AppConstants {
    static let appGroupID = "group.com.socialmediawidget.thing"
    static let cloudKitContainerID = "iCloud.com.socialmediawidget.thing"

    static let sharedDefaultsSuite = appGroupID

    // Replace with your Discord app credentials from https://discord.com/developers/applications
    static let discordClientID = "YOUR_DISCORD_CLIENT_ID"
    static let discordRedirectURI = "socialwidget://discord-callback"

    static let maxFriends = 1

    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let currentUserID = "currentUserID"
        static let widgetTheme = "widgetTheme"
        static let widgetPlatform = "widgetPlatform"
        static let widgetConfigJSON = "widgetConfigJSON"
        static let cachedStatsJSON = "cachedStatsJSON"
        static let lastStatsUpdate = "lastStatsUpdate"
        static let notificationsEnabled = "notificationsEnabled"
        static let clipboardTrackingEnabled = "clipboardTrackingEnabled"
        static let matchWidgetTheme = "matchWidgetTheme"
        static let appThemeOverride = "appThemeOverride"
        static let messagesJSON = "messagesJSON"
        static let commentsJSON = "commentsJSON"
        static let chartDays = "chartDays"
    }

    enum RecordTypes {
        static let user = "SMWUser"
        static let shareEvent = "SMWShareEvent"
        static let friendship = "SMWFriendship"
        static let message = "SMWMessage"
        static let comment = "SMWComment"
    }
}
