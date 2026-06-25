import Foundation
@testable import Tomate

/// Reproduces `TimerView` / `RootView` timer button handlers with injectable dates.
///
/// · `tapReprendre` / `tapPause`(running) / `tapPasser` après changement de phase → lance le chrono.
/// · `tapPause`(running) / `tapPasser` / `tapReinitialiser` → flush en base à l’instant du clic.
struct TimerTestHarness {
    let timer: PomodoroTimer

    /// « Démarrer » / « Reprendre » — play/pause toggle while idle.
    func tapReprendre(at date: Date) {
        timer.togglePause(at: date)
    }

    /// « Pause » — pause toggle while running.
    func tapPause(at date: Date) {
        timer.togglePause(at: date)
    }

    /// « Passer » — skip button.
    func tapPasser(at date: Date) {
        timer.skip(at: date)
    }

    /// « Réinitialiser » — reset button.
    func tapReinitialiser(at date: Date) {
        timer.reset(at: date)
    }

    /// Timer icon on timer tab — toolbar resets before switching.
    func tapToolbarTimerReset(at date: Date) {
        timer.reset(at: date)
    }

    /// Live-display poll while the chrono runs (`LiveDisplayDriver`).
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

    /// Quit / Cmd+Q — same handler as the reset button.
    func appWillTerminate(at date: Date) {
        timer.reset(at: date)
    }
}
