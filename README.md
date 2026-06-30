# Tomate

Native Pomodoro timer for macOS. Simple, lightweight, and fully local.

## Features

- **Timer:** Focus and break cycles. Start, pause, skip, or reset anytime.
- **Timeline:** Hour-by-hour view of your day’s work sessions.
- **Stats:** Day and week views: sessions completed, breaks taken, total focus time.
- **Local only:** History stays on your Mac. No account, no cloud.
- **Settings:** Session and break lengths (25 / 5 min by default), auto-start breaks, language, first day of week.
- **Language:** 🇬🇧 English / 🇫🇷 Français; follows your Mac’s language, or pick one in settings.
- **Reliable:** Pauses when the Mac sleeps or locks; picks up where you left off.

## Requirements

- macOS 14+

## Install

1. [Download Tomate](https://github.com/secardia/tomate/releases/latest/download/Tomate.zip)
2. Unzip, then drag `Tomate.app` to Applications
3. First launch: right-click → **Open** (macOS security warning without Apple notarization)

**Settings:** Tomate menu → Settings, or `⌘ ,`

## Development

Requires [Xcode](https://developer.apple.com/xcode/) 26+.

**Run** (Debug build):

```bash
./debug.sh
```

**Build, zip, and install** to `/Applications` (Release):

```bash
./install.sh
```

Elsewhere: `INSTALL_DIR=./tmp ./install.sh`

The zip for [GitHub Releases](https://github.com/secardia/tomate/releases) is written to `build/Build/Products/Release/Tomate.zip`.

## Tests

```bash
xcodebuild \
  -project Tomate.xcodeproj \
  -scheme Tomate \
  -destination 'platform=macOS' \
  test
```

## Structure

```
Tomate/
  Models/         Timer, sessions, stats, timeline layout
  Views/          SwiftUI screens and components
  Persistence/    Core Data stack and entities
  Preferences/    UserDefaults keys and accessors
  Platform/       Sleep/lock monitors, window management
  Theme/          Colors, strings, layout metrics
TomateTests/      Unit tests
Resources/        App icon and asset catalog
debug.sh                        Debug build + launch
install.sh                      Release build, zip, and install to Applications
docs/generate-screenshots.sh    Regenerate docs/screenshots PNGs
```

## License

Tomate is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.