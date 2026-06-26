#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT/Tomate.xcodeproj"
TARGET="Tomate"
CONFIG="Release"
DERIVED_DATA="$ROOT/build"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
DEST="$INSTALL_DIR/$TARGET.app"

if ! xcodebuild -version &>/dev/null; then
  if [[ -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  else
    echo "error: Xcode is required." >&2
    exit 1
  fi
fi

echo "→ Generating app icon…"
python3 "$ROOT/scripts/generate_app_icon.py"

INTERMEDIATES="$DERIVED_DATA/Build/Intermediates.noindex/Tomate.build/$CONFIG/Tomate.build"
rm -rf "${INTERMEDIATES}"/assetcatalog*
rm -f "$DERIVED_DATA/Build/Products/$CONFIG/$TARGET.app/Contents/Resources/AppIcon.icns"

echo "→ Building ($CONFIG)…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$TARGET" \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=YES \
  DEVELOPMENT_TEAM=""

APP="$DERIVED_DATA/Build/Products/$CONFIG/$TARGET.app"
if [[ ! -d "$APP" ]]; then
  echo "error: binary not found: $APP" >&2
  exit 1
fi

echo "→ Installing to ${DEST}…"
if [[ -d "$DEST" ]]; then
  rm -rf "$DEST"
fi
ditto "$APP" "$DEST"
xattr -cr "$DEST" 2>/dev/null || true
touch "$DEST"

echo ""
echo "✓ Tomate installed to $DEST"
echo "  Drag the icon to the Dock to pin it."
