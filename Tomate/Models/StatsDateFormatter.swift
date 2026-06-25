import Foundation

enum StatsDateFormatter {
    private static let locale = Locale(identifier: "fr_FR")

    private static let dayTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE d MMMM"
        return formatter
    }()

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "d MMMM"
        return formatter
    }()

    private static let shortWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEE"
        return formatter
    }()

    static func dayTitle(_ date: Date) -> String {
        dayTitleFormatter.string(from: date).capitalized
    }

    static func weekTitle(containing date: Date, calendar: Calendar = StatsCalendar.french) -> String {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return ""
        }
        return "Semaine du \(monthDayFormatter.string(from: weekStart))"
    }

    static func shortWeekday(_ date: Date) -> String {
        shortWeekdayFormatter.string(from: date).capitalized
    }
}
