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
    echo "error: Xcode est requis." >&2
    exit 1
  fi
fi

echo "→ Génération de l'icône…"
python3 "$ROOT/scripts/generate_app_icon.py"

INTERMEDIATES="$DERIVED_DATA/Build/Intermediates.noindex/Tomate.build/$CONFIG/Tomate.build"
rm -rf "${INTERMEDIATES}"/assetcatalog*
rm -f "$DERIVED_DATA/Build/Products/$CONFIG/$TARGET.app/Contents/Resources/AppIcon.icns"

echo "→ Compilation ($CONFIG)…"
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
  echo "error: binaire introuvable : $APP" >&2
  exit 1
fi

echo "→ Installation dans ${DEST}…"
if [[ -d "$DEST" ]]; then
  rm -rf "$DEST"
fi
ditto "$APP" "$DEST"
xattr -cr "$DEST" 2>/dev/null || true
touch "$DEST"

echo ""
echo "✓ Tomate est installée dans $DEST"
echo "  Glisse l'icône dans le Dock pour l'épingler."
