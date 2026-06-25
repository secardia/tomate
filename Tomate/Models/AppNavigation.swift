enum AppScreen {
    case timer
    case stats
}

enum StatsPeriod: String, CaseIterable {
    case day = "Jour"
    case week = "Semaine"
}
