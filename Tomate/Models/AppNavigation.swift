enum AppScreen {
    case timer
    case stats
}

enum StatsPeriod: CaseIterable, Hashable {
    case day
    case week

    var label: String {
        switch self {
        case .day: AppStrings.Stats.day
        case .week: AppStrings.Stats.week
        }
    }
}
