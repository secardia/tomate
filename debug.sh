#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT/Tomate.xcodeproj"
CONFIG="Debug"
DERIVED_DATA="$ROOT/build"
APP="$DERIVED_DATA/Build/Products/$CONFIG/Tomate Dev.app"

if ! xcodebuild -version &>/dev/null; then
  if [[ -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  else
    echo "error: Xcode est requis (pas seulement les Command Line Tools)." >&2
    echo "Installez Xcode depuis l'App Store, puis :" >&2
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
  fi
fi

echo "→ Génération de l'icône…"
python3 "$ROOT/scripts/generate_app_icon.py"

# Xcode peut réutiliser un AppIcon.icns en cache même quand les PNG changent.
INTERMEDIATES="$DERIVED_DATA/Build/Intermediates.noindex/Tomate.build/$CONFIG/Tomate.build"
rm -rf "${INTERMEDIATES}"/assetcatalog*
rm -f "$APP/Contents/Resources/AppIcon.icns"

echo "→ Compilation ($CONFIG)…"
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
  echo "error: binaire introuvable : $APP" >&2
  exit 1
fi

touch "$APP"
xattr -cr "$APP" 2>/dev/null || true
osascript -e 'tell application "Tomate Dev" to quit' 2>/dev/null || true

echo "→ Lancement de $APP"
open "$APP"
