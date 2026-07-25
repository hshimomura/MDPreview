#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
APP_PATH="$PROJECT_ROOT/dist/MDPreview.app"

cd "$PROJECT_ROOT"

export CLANG_MODULE_CACHE_PATH="$PROJECT_ROOT/.build/module-cache"
export SWIFT_MODULECACHE_PATH="$PROJECT_ROOT/.build/module-cache"

"$PROJECT_ROOT/Scripts/build-icon.sh"

swift build -c release --arch arm64
BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"

mkdir -p \
    "$APP_PATH/Contents/MacOS" \
    "$APP_PATH/Contents/Resources/ThirdPartyLicenses"

/usr/bin/ditto "$BIN_DIR/MDPreview" "$APP_PATH/Contents/MacOS/MDPreview"
/usr/bin/ditto "$PROJECT_ROOT/Packaging/Info.plist" "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleExecutable -string MDPreview \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleIdentifier \
    -string io.github.hshimomura.MDViewer \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleShortVersionString -string 1.0 \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleVersion -string 12 \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace LSMinimumSystemVersion -string 26.0 \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/ditto "$PROJECT_ROOT/Resources/AppIcon.icns" \
    "$APP_PATH/Contents/Resources/AppIcon.icns"
/usr/bin/ditto "$PROJECT_ROOT/THIRD_PARTY_NOTICES.md" \
    "$APP_PATH/Contents/Resources/THIRD_PARTY_NOTICES.md"
/usr/bin/ditto "$PROJECT_ROOT/Packaging/PrivacyInfo.xcprivacy" \
    "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy"
/usr/bin/ditto "$PROJECT_ROOT/Legal/Prism-LICENSE.txt" \
    "$APP_PATH/Contents/Resources/ThirdPartyLicenses/Prism-LICENSE.txt"

for resource_bundle in "$BIN_DIR"/*.bundle; do
    if [[ -d "$resource_bundle" ]]; then
        /usr/bin/ditto "$resource_bundle" \
            "$APP_PATH/Contents/Resources/${resource_bundle:t}"
    fi
done

typeset -A license_sources
license_sources=(
    "Textual" "$PROJECT_ROOT/.build/checkouts/textual/LICENSE"
    "SwiftUIMath" "$PROJECT_ROOT/.build/checkouts/swiftui-math/LICENSE"
    "ConcurrencyExtras" "$PROJECT_ROOT/.build/checkouts/swift-concurrency-extras/LICENSE"
    "Mermaid" "$PROJECT_ROOT/Legal/Mermaid-LICENSE.txt"
)

for component source_path in "${(@kv)license_sources}"; do
    if [[ -f "$source_path" ]]; then
        /usr/bin/ditto "$source_path" \
            "$APP_PATH/Contents/Resources/ThirdPartyLicenses/$component-LICENSE.txt"
    fi
done

/usr/bin/codesign --force --deep --sign - "$APP_PATH"
/usr/bin/plutil -lint "$APP_PATH/Contents/Info.plist"
/usr/bin/codesign --verify --deep --strict "$APP_PATH"

print "Built $APP_PATH"
