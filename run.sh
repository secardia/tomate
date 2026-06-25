#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT/Tomate.xcodeproj"
TARGET="Tomate"
CONFIG="${CONFIG:-Debug}"
DERIVED_DATA="$ROOT/build"

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

echo "→ Compilation ($CONFIG)…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$TARGET" \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  CODE_SIGNING_ALLOWED=NO

APP="$DERIVED_DATA/Build/Products/$CONFIG/$TARGET.app"

if [[ ! -d "$APP" ]]; then
  echo "error: binaire introuvable : $APP" >&2
  exit 1
fi

echo "→ Lancement de $APP"
open "$APP"
