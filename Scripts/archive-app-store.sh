#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
ARCHIVE_PATH="$PROJECT_ROOT/dist/MDViewer-AppStore.xcarchive"
EXPORT_PATH="$PROJECT_ROOT/dist/AppStoreExport"
EXPORT_OPTIONS="$PROJECT_ROOT/Packaging/ExportOptions.plist"

cd "$PROJECT_ROOT"

"$PROJECT_ROOT/Scripts/generate-xcode-project.sh"

xcodebuild \
    -project "$PROJECT_ROOT/MDViewer.xcodeproj" \
    -scheme MDPreview \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    archive

print "Archived $ARCHIVE_PATH"

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates

print "Exported App Store package to $EXPORT_PATH"
