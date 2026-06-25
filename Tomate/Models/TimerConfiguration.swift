struct TimerConfiguration: Equatable {
    var focusDurationSeconds: Int
    var restDurationSeconds: Int
    var autoStartBreaks: Bool
    /// Durée active minimale pour +1 dans les colonnes « sessions » Jour/Semaine (pas pour la timeline ni le cumul).
    var minimumSessionCountSeconds: Int

    static let defaultMinimumSessionCountSeconds = 60

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
