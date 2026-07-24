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

[[ "$document_role" == "Viewer" ]]
[[ "$markdown_type" == "net.daringfireball.markdown" ]]

print "Verified read-only Markdown viewer registration."
