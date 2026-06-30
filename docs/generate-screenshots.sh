#!/usr/bin/env bash
set -euo pipefail

DOCS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DOCS/.." && pwd)"
PROJECT="$ROOT/Tomate.xcodeproj"
DERIVED_DATA="$ROOT/build"

if ! xcodebuild -version &>/dev/null; then
  if [[ -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  else
    echo "error: Xcode is required." >&2
    exit 1
  fi
fi

export TZ=Europe/Paris

echo "→ Generating screenshots (TZ=Europe/Paris)…"
xcodebuild \
  -project "$PROJECT" \
  -scheme Tomate \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -only-testing:TomateTests/ScreenshotTests/testGenerateScreenshots \
  test

echo ""
echo "✓ Screenshots written to docs/screenshots/"
