import Foundation

/// Calendar weekday index (1 = Sunday … 7 = Saturday), matching `Calendar.firstWeekday`.
struct WeekStartDay: Hashable, Identifiable {
    let rawValue: Int

    var id: Int { rawValue }

    init(rawValue: Int) {
        self.rawValue = min(7, max(1, rawValue))
    }

    static var allCases: [WeekStartDay] {
        (1...7).map { WeekStartDay(rawValue: $0) }
    }

    static var systemDefault: WeekStartDay {
        WeekStartDay(rawValue: Calendar.current.firstWeekday)
    }

    static let monday = WeekStartDay(rawValue: 2)

    var label: String {
        StatsDateFormatter.weekdayName(for: rawValue)
    }
}
