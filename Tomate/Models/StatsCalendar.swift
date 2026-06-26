import Foundation

enum StatsCalendar {
    static var stats: Calendar {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: AppPreferences.language.localeIdentifier)
        calendar.firstWeekday = AppPreferences.firstWeekday.rawValue
        return calendar
    }
}
