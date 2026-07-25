#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

cd "$PROJECT_ROOT"

"$PROJECT_ROOT/Scripts/build-icon.sh"
xcodegen generate --spec "$PROJECT_ROOT/project.yml"

print "Generated $PROJECT_ROOT/MDViewer.xcodeproj"
