#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
ARCHIVE_PATH="$PROJECT_ROOT/dist/MDViewer-AppStore.xcarchive"
BASE_OPTIONS="$PROJECT_ROOT/Packaging/ExportOptions.plist"
TEMP_PARENT="$(/usr/bin/mktemp -d /private/tmp/mdviewer-upload.XXXXXX)"
UPLOAD_OPTIONS="$TEMP_PARENT/UploadOptions.plist"
EXPORT_PATH="$TEMP_PARENT/export"

cleanup() {
    /bin/rm -rf "$TEMP_PARENT"
}
trap cleanup EXIT

if [[ ! -d "$ARCHIVE_PATH" ]]; then
    print -u2 "Missing App Store archive: $ARCHIVE_PATH"
    exit 1
fi

/usr/bin/ditto "$BASE_OPTIONS" "$UPLOAD_OPTIONS"
/usr/bin/plutil -replace destination -string upload "$UPLOAD_OPTIONS"

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$UPLOAD_OPTIONS" \
    -allowProvisioningUpdates

marketing_version="$(/usr/libexec/PlistBuddy \
    -c 'Print :ApplicationProperties:CFBundleShortVersionString' \
    "$ARCHIVE_PATH/Info.plist")"
build_version="$(/usr/libexec/PlistBuddy \
    -c 'Print :ApplicationProperties:CFBundleVersion' \
    "$ARCHIVE_PATH/Info.plist")"

print "Uploaded $marketing_version ($build_version) to App Store Connect."
