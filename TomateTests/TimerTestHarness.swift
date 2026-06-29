import Foundation
@testable import Tomate

/// Reproduces `TimerView` / `RootView` timer button handlers with injectable dates.
///
/// · `tapStartOrResume` / `tapPause`(running) / `tapSkip` after phase change → starts the timer.
/// · `tapPause`(running) / `tapSkip` / `tapReset` → flush to DB at click time.
struct TimerTestHarness {
    let timer: PomodoroTimer

    /// "Start" / "Resume" — play/pause toggle while idle.
    func tapStartOrResume(at date: Date) {
        timer.togglePause(at: date)
    }

    /// "Pause" — pause toggle while running.
    func tapPause(at date: Date) {
        timer.togglePause(at: date)
    }

    /// "Skip" — skip button.
    func tapSkip(at date: Date) {
        timer.skip(at: date)
    }

    /// "Reset" — reset button.
    func tapReset(at date: Date) {
        timer.reset(at: date)
    }

    /// Timer icon on timer tab — toolbar resets before switching.
    func tapToolbarTimerReset(at date: Date) {
        timer.reset(at: date)
    }

    /// Live-display poll while the timer runs (`LiveDisplayDriver`).
    func tickLiveDisplay(at date: Date, onPhaseChange: () -> Void = {}) {
        timer.poll(at: date, onPhaseChange: onPhaseChange)
    }

    /// Completion check only (legacy alias for tests).
    func tickCompletion(at date: Date) {
        timer.checkCompletion(at: date)
    }

    func systemWillSleep(at date: Date) {
        timer.handleSystemWillSleep(at: date)
    }

    func systemDidWake(at date: Date) {
        timer.handleSystemDidWake(at: date)
    }

    func screenDidLock(at date: Date) {
        timer.handleAutomaticSuspend(.screenLock, at: date)
    }

    func screenDidUnlock(at date: Date) {
        timer.handleAutomaticResume(.screenLock, at: date)
    }

    func displayDidSleep(at date: Date) {
        timer.handleAutomaticSuspend(.displaySleep, at: date)
    }

    func displayDidWake(at date: Date) {
        timer.handleAutomaticResume(.displaySleep, at: date)
    }

    /// Quit / Cmd+Q — same handler as the reset button.
    func appWillTerminate(at date: Date) {
        timer.reset(at: date)
    }
}

enum TestPreferences {
    /// Registers defaults, then pins locale/calendar for deterministic tests.
    static func register() {
        AppPreferences.register()
        AppPreferences.language = .english
        AppPreferences.firstWeekday = .monday
    }
}
