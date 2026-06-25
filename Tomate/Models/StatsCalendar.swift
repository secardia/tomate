import Foundation

enum StatsCalendar {
    static var french: Calendar {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "fr_FR")
        calendar.firstWeekday = 2
        return calendar
    }
}
