import AppKit
import Foundation

/// App preferences — UserDefaults (plist in ~/Library/Preferences).
enum AppPreferences {
    private static let defaults = UserDefaults.standard

    static let languageKey = "preferences.language"
    static let firstWeekdayKey = "preferences.calendar.firstWeekday"

    private enum Keys {
        static let language = languageKey
        static let firstWeekday = firstWeekdayKey
        static let focusDurationSeconds = "preferences.timer.focusDurationSeconds"
        static let restDurationSeconds = "preferences.timer.restDurationSeconds"
        static let autoStartBreaks = "preferences.timer.autoStartBreaks"
        static let minimumPauseGapSeconds = "preferences.timeline.minimumPauseGapSeconds"

        static let windowFrameX = "preferences.window.frame.x"
        static let windowFrameY = "preferences.window.frame.y"
        static let windowFrameWidth = "preferences.window.frame.width"
        static let windowFrameHeight = "preferences.window.frame.height"
    }

    private enum Defaults {
        static let focusDurationSeconds = 25 * 60
        static let restDurationSeconds = 5 * 60
        static let autoStartBreaks = true
        static let minimumPauseGapSeconds = 20 * 60
    }

    static func register() {
        defaults.register(defaults: [
            Keys.language: AppLanguage.systemDefault.rawValue,
            Keys.firstWeekday: WeekStartDay.systemDefault.rawValue,
            Keys.focusDurationSeconds: Defaults.focusDurationSeconds,
            Keys.restDurationSeconds: Defaults.restDurationSeconds,
            Keys.autoStartBreaks: Defaults.autoStartBreaks,
            Keys.minimumPauseGapSeconds: Defaults.minimumPauseGapSeconds,
        ])
    }

    // MARK: - Language

    static var language: AppLanguage {
        get {
            guard let raw = defaults.string(forKey: Keys.language),
                  let language = AppLanguage(rawValue: raw) else {
                return AppLanguage.systemDefault
            }
            return language
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.language) }
    }

    // MARK: - Calendar

    static var firstWeekday: WeekStartDay {
        get {
            guard defaults.object(forKey: Keys.firstWeekday) != nil else {
                return WeekStartDay.systemDefault
            }
            let value = defaults.integer(forKey: Keys.firstWeekday)
            guard (1...7).contains(value) else {
                return WeekStartDay.systemDefault
            }
            return WeekStartDay(rawValue: value)
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.firstWeekday) }
    }

    // MARK: - Timer

    static var focusDurationSeconds: Int {
        get { positiveInt(forKey: Keys.focusDurationSeconds, default: Defaults.focusDurationSeconds) }
        set { defaults.set(newValue, forKey: Keys.focusDurationSeconds) }
    }

    static var restDurationSeconds: Int {
        get { positiveInt(forKey: Keys.restDurationSeconds, default: Defaults.restDurationSeconds) }
        set { defaults.set(newValue, forKey: Keys.restDurationSeconds) }
    }

    static var autoStartBreaks: Bool {
        get {
            guard defaults.object(forKey: Keys.autoStartBreaks) != nil else {
                return Defaults.autoStartBreaks
            }
            return defaults.bool(forKey: Keys.autoStartBreaks)
        }
        set { defaults.set(newValue, forKey: Keys.autoStartBreaks) }
    }

    // MARK: - Timeline

    static var minimumPauseGapSeconds: Int {
        get { positiveInt(forKey: Keys.minimumPauseGapSeconds, default: Defaults.minimumPauseGapSeconds) }
        set { defaults.set(newValue, forKey: Keys.minimumPauseGapSeconds) }
    }

    // MARK: - Window

    static func saveWindowFrame(_ frame: NSRect) {
        defaults.set(frame.origin.x, forKey: Keys.windowFrameX)
        defaults.set(frame.origin.y, forKey: Keys.windowFrameY)
        defaults.set(frame.size.width, forKey: Keys.windowFrameWidth)
        defaults.set(frame.size.height, forKey: Keys.windowFrameHeight)
    }

    static func loadWindowFrame(minFrameSize: NSSize) -> NSRect? {
        guard defaults.object(forKey: Keys.windowFrameWidth) != nil else { return nil }

        var frame = NSRect(
            x: defaults.double(forKey: Keys.windowFrameX),
            y: defaults.double(forKey: Keys.windowFrameY),
            width: defaults.double(forKey: Keys.windowFrameWidth),
            height: defaults.double(forKey: Keys.windowFrameHeight)
        )

        guard frame.width > 0, frame.height > 0 else { return nil }

        frame.size.width = max(frame.size.width, minFrameSize.width)
        frame.size.height = max(frame.size.height, minFrameSize.height)

        guard let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(frame) })
            ?? NSScreen.main else {
            return frame
        }

        let visible = screen.visibleFrame
        frame.origin.x = min(max(frame.origin.x, visible.minX), visible.maxX - frame.width)
        frame.origin.y = min(max(frame.origin.y, visible.minY), visible.maxY - frame.height)
        return frame
    }

    private static func positiveInt(forKey key: String, default defaultValue: Int) -> Int {
        let value = defaults.integer(forKey: key)
        return value > 0 ? value : defaultValue
    }
}
