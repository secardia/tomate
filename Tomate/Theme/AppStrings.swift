enum AppStrings {
    private static var l: LocalizedStrings {
        switch AppPreferences.language {
        case .english: .english
        case .french: .french
        }
    }

    enum Phase {
        static var focus: String { l.phaseFocus }
        static var rest: String { l.phaseRest }
    }

    enum Timer {
        static var pause: String { l.timerPause }
        static var start: String { l.timerStart }
        static var resume: String { l.timerResume }
        static var skip: String { l.timerSkip }
        static var reset: String { l.timerReset }
    }

    enum Stats {
        static var day: String { l.statsDay }
        static var week: String { l.statsWeek }
        static var sessions: String { l.statsSessions }
        static var pauses: String { l.statsPauses }
        static var today: String { l.statsToday }
    }

    enum Settings {
        static var title: String { l.settingsTitle }
        static var language: String { l.settingsLanguage }
        static var firstWeekday: String { l.settingsFirstWeekday }
        static var focusDuration: String { l.settingsFocusDuration }
        static var restDuration: String { l.settingsRestDuration }
        static var autoStartBreaks: String { l.settingsAutoStartBreaks }
    }
}

private struct LocalizedStrings {
    let phaseFocus: String
    let phaseRest: String
    let timerPause: String
    let timerStart: String
    let timerResume: String
    let timerSkip: String
    let timerReset: String
    let statsDay: String
    let statsWeek: String
    let statsSessions: String
    let statsPauses: String
    let statsToday: String
    let settingsTitle: String
    let settingsLanguage: String
    let settingsFirstWeekday: String
    let settingsFocusDuration: String
    let settingsRestDuration: String
    let settingsAutoStartBreaks: String

    static let english = LocalizedStrings(
        phaseFocus: "Focus",
        phaseRest: "Break",
        timerPause: "Pause",
        timerStart: "Start",
        timerResume: "Resume",
        timerSkip: "Skip",
        timerReset: "Reset",
        statsDay: "Day",
        statsWeek: "Week",
        statsSessions: "Sessions",
        statsPauses: "Breaks",
        statsToday: "Today",
        settingsTitle: "Settings",
        settingsLanguage: "Language",
        settingsFirstWeekday: "First day of week",
        settingsFocusDuration: "Focus duration",
        settingsRestDuration: "Break duration",
        settingsAutoStartBreaks: "Start breaks automatically"
    )

    static let french = LocalizedStrings(
        phaseFocus: "Concentration",
        phaseRest: "Pause",
        timerPause: "Pause",
        timerStart: "Démarrer",
        timerResume: "Reprendre",
        timerSkip: "Passer",
        timerReset: "Réinitialiser",
        statsDay: "Jour",
        statsWeek: "Semaine",
        statsSessions: "Sessions",
        statsPauses: "Pauses",
        statsToday: "Aujourd'hui",
        settingsTitle: "Réglages",
        settingsLanguage: "Langue",
        settingsFirstWeekday: "Premier jour de la semaine",
        settingsFocusDuration: "Durée de concentration",
        settingsRestDuration: "Durée de pause",
        settingsAutoStartBreaks: "Démarrer les pauses automatiquement"
    )
}
