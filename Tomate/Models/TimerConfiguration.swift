import Foundation

struct TimerConfiguration: Equatable {
    var focusDurationSeconds: Int
    var restDurationSeconds: Int
    var autoStartBreaks: Bool
    var minimumSessionCountSeconds: Int

    /// Minimum active duration to count +1 in Day/Week session columns (not for timeline or cumulative time).
    static let defaultMinimumSessionCountSeconds = 60
    /// Minimum gap between focus blocks to show pause start/end labels on the day timeline.
    static let minimumTimelinePauseGap: TimeInterval = 15 * 60

    static func fromPreferences() -> TimerConfiguration {
        TimerConfiguration(
            focusDurationSeconds: AppPreferences.focusDurationSeconds,
            restDurationSeconds: AppPreferences.restDurationSeconds,
            autoStartBreaks: AppPreferences.autoStartBreaks,
            minimumSessionCountSeconds: defaultMinimumSessionCountSeconds
        )
    }

    func durationSeconds(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .focus: focusDurationSeconds
        case .rest: restDurationSeconds
        }
    }
}
