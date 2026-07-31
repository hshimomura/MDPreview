#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
APP_PATH="$PROJECT_ROOT/dist/MDPreview.app"

if [[ ! -d "$APP_PATH" ]]; then
    print -u2 "Missing app bundle: $APP_PATH"
    exit 1
fi

/usr/bin/plutil -lint "$APP_PATH/Contents/Info.plist"
/usr/bin/codesign --verify --deep --strict "$APP_PATH"

document_role="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleDocumentTypes:0:CFBundleTypeRole" \
    "$APP_PATH/Contents/Info.plist")"
markdown_type="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleDocumentTypes:0:LSItemContentTypes:0" \
    "$APP_PATH/Contents/Info.plist")"
icon_file="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleIconFile" \
    "$APP_PATH/Contents/Info.plist")"
bundle_identifier="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleIdentifier" \
    "$APP_PATH/Contents/Info.plist")"
marketing_version="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleShortVersionString" \
    "$APP_PATH/Contents/Info.plist")"
build_version="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleVersion" \
    "$APP_PATH/Contents/Info.plist")"
app_category="$(/usr/libexec/PlistBuddy \
    -c "Print :LSApplicationCategoryType" \
    "$APP_PATH/Contents/Info.plist")"

[[ "$document_role" == "Viewer" ]]
[[ "$markdown_type" == "net.daringfireball.markdown" ]]
[[ "$icon_file" == "AppIcon.icns" ]]
[[ "$bundle_identifier" == "io.github.hshimomura.MDViewer" ]]
[[ "$marketing_version" == "1.1" ]]
[[ "$build_version" == "14" ]]
[[ "$app_category" == "public.app-category.productivity" ]]
[[ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]]
[[ -f "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy" ]]
[[ -f \
    "$APP_PATH/Contents/Resources/MDPreview_MDPreview.bundle/Resources/Mermaid/mermaid.min.js" ]]
[[ -f \
    "$APP_PATH/Contents/Resources/ThirdPartyLicenses/Mermaid-LICENSE.txt" ]]

print "Verified MD Viewer 1.1 (14), read-only registration, Productivity category, privacy manifest, app icon, and offline Mermaid runtime."
