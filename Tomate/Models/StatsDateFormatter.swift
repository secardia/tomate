import Foundation

enum StatsDateFormatter {
    private static var locale: Locale {
        Locale(identifier: AppPreferences.language.localeIdentifier)
    }

    static func dayTitle(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle()
                .weekday(.wide)
                .day()
                .month(.wide)
                .locale(locale)
        )
    }

    static func weekTitle(containing date: Date, calendar: Calendar = StatsCalendar.stats) -> String {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return ""
        }
        let datePart = weekStart.formatted(
            Date.FormatStyle()
                .month(.wide)
                .day()
                .locale(locale)
        )
        switch AppPreferences.language {
        case .english:
            return "Week of \(datePart)"
        case .french:
            return "Semaine du \(datePart)"
        }
    }

    static func shortWeekday(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle()
                .weekday(.abbreviated)
                .locale(locale)
        )
    }

    /// Full weekday name for settings; `calendarIndex` is 1 (Sunday) … 7 (Saturday).
    static func weekdayName(for calendarIndex: Int) -> String {
        var calendar = Calendar.current
        calendar.locale = locale
        let index = calendarIndex - 1
        guard calendar.weekdaySymbols.indices.contains(index) else {
            return "\(calendarIndex)"
        }
        return calendar.weekdaySymbols[index].capitalized
    }
}
