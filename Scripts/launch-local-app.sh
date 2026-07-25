#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
APP_PATH="$PROJECT_ROOT/dist/MDPreview.app"

if [[ ! -d "$APP_PATH" ]]; then
    print -u2 "Missing app bundle: $APP_PATH"
    print -u2 "Run ./Scripts/build-app.sh first."
    exit 1
fi

typeset -a document_paths
document_paths=("$@")

if (( ${#document_paths} == 0 )); then
    document_paths=("$PROJECT_ROOT/Sample.md")
fi

typeset -a open_arguments
open_arguments=(-na "$APP_PATH")

for document_path in "${document_paths[@]}"; do
    if [[ ! -f "$document_path" ]]; then
        print -u2 "Missing Markdown document: $document_path"
        exit 1
    fi
    open_arguments+=("$document_path")
done

# Launch the .app through LaunchServices. Executing Contents/MacOS/MDPreview
# directly bypasses normal macOS application registration and can abort inside
# HIServices before SwiftUI creates the first scene.
/usr/bin/open "${open_arguments[@]}"
