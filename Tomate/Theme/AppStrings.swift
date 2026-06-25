enum AppStrings {
    enum Phase {
        static let focus = "Concentration"
        static let rest = "Pause"
    }

    enum Timer {
        static let pause = "Pause"
        static let start = "Démarrer"
        static let resume = "Reprendre"
        static let skip = "Passer"
        static let reset = "Réinitialiser"
    }

    enum Stats {
        static let sessions = "Sessions"
        static let pauses = "Pauses"
        static let today = "Aujourd'hui"
    }

    enum Settings {
        static let title = "Réglages"
        static let focusDuration = "Durée de concentration"
        static let restDuration = "Durée de pause"
        static let autoStartBreaks = "Démarrer les pauses automatiquement"
        static let durationHint = "Les nouvelles durées s'appliquent à la prochaine phase ou après réinitialisation."
    }
}
