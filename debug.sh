#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT/Tomate.xcodeproj"
CONFIG="Debug"
DERIVED_DATA="$ROOT/build"
APP="$DERIVED_DATA/Build/Products/$CONFIG/Tomate Debug.app"

if ! xcodebuild -version &>/dev/null; then
  if [[ -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  else
    echo "error: Xcode is required (not just Command Line Tools)." >&2
    echo "Install Xcode from the App Store, then:" >&2
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
  fi
fi

echo "→ Building ($CONFIG)…"
xcodebuild \
  -project "$PROJECT" \
  -scheme Tomate \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=YES \
  DEVELOPMENT_TEAM=""

if [[ ! -d "$APP" ]]; then
  echo "error: binary not found: $APP" >&2
  exit 1
fi

touch "$APP"
xattr -cr "$APP" 2>/dev/null || true
osascript -e 'tell application "Tomate Debug" to quit' 2>/dev/null || true

echo "→ Launching $APP"
open "$APP"
