# ShareTrack

iOS app + widgets for tracking videos shared between two people across social platforms.

## Stack

- **SwiftUI** · iOS 17+
- **WidgetKit** — home screen widgets (single-platform + overview)
- **CloudKit** — sync share events between paired users
- **App Groups** — shared state across app, widget, and share extension

## Targets

| Target | Bundle ID suffix | Role |
|--------|------------------|------|
| ShareTrack | `.thing` | Main app |
| ShareTrack Widget | `.thing.widget` | WidgetKit extension |
| Track Share | `.thing.share` | Share extension |

## Tracking model

Third-party apps (Instagram, TikTok, etc.) do not expose DM APIs. ShareTrack uses:

1. **Share extension** — Share → Track Share from any social app
2. **Clipboard detection** — copy a link, confirm in-app
3. **Manual log** — Settings → Log a Share

Events sync via CloudKit public database record types: `SMWUser`, `SMWShareEvent`, `SMWFriendship`.

## Widget customization

22 themes · 6 layout styles (glass, card, neon, mesh, outline, flat) · accent presets + custom color picker. Config persisted to App Group `UserDefaults` as `widgetConfigJSON`.

## Setup

```bash
./setup.sh open   # generate Xcode project and open
```

1. Apple Developer: enable App Groups + iCloud (CloudKit) on `com.socialmediawidget.thing`
2. App Group: `group.com.socialmediawidget.thing`
3. iCloud container: `iCloud.com.socialmediawidget.thing`
4. Set signing team on all three targets in Xcode

Optional Discord OAuth: set `discordClientID` in `Shared/AppConstants.swift`.

## TestFlight

```bash
./setup.sh archive
```

Or Product → Archive → Distribute to App Store Connect.

## Project layout

```
Shared/           Models, services, widget renderer (app + extensions)
SocialMediaWidgetThing/   Main SwiftUI app
SocialWidgetExtension/    WidgetKit targets
ShareTrackerExtension/    Share extension
project.yml       XcodeGen spec
```
\n\n---\n\n**Author:** [Dhruv Hegde](https://github.com/DDVHegde100) · CS @ University of Michigan\n
**License:** [MIT](LICENSE)
