#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="SocialMediaWidgetThing"
ARCHIVE_PATH="$PROJECT_DIR/build/ShareTrack.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"

cd "$PROJECT_DIR"
xcodegen generate

case "${1:-}" in
  open)
    open "$PROJECT_DIR/SocialMediaWidgetThing.xcodeproj"
    ;;
  archive)
    echo "Archiving for TestFlight..."
    xcodebuild archive \
        -project "$PROJECT_DIR/SocialMediaWidgetThing.xcodeproj" \
        -scheme "$SCHEME" \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=iOS" \
        CODE_SIGN_STYLE=Automatic

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist"

    echo "Done: $EXPORT_PATH"
    ;;
  *)
    echo "ShareTrack — ready to build"
    echo ""
    echo "  ./setup.sh open      Open in Xcode"
    echo "  ./setup.sh archive   Archive for TestFlight"
    echo ""
    echo "One-time setup:"
    echo "  1. Apple Developer: App ID com.socialmediawidget.thing"
    echo "     Capabilities: App Groups, iCloud/CloudKit"
    echo "  2. App Group: group.com.socialmediawidget.thing"
    echo "  3. iCloud container: iCloud.com.socialmediawidget.thing"
    echo "  4. App Store Connect: create app 'ShareTrack'"
    echo "  5. Xcode: set Team on all 3 targets"
    echo ""
    echo "Tracking videos (no DM API access):"
    echo "  • Share extension: Share → Track Share"
    echo "  • Clipboard banner when you copy a link"
    echo "  • Manual log in Settings"
    ;;
esac
