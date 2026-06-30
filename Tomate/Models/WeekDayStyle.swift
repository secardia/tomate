import Foundation

struct WeekDayStyle: Equatable {
    let isToday: Bool
    let isPastOrToday: Bool

    static func make(date: Date, today: Date, calendar: Calendar) -> WeekDayStyle {
        let startOfToday = calendar.startOfDay(for: today)
        let startOfDate = calendar.startOfDay(for: date)
        return WeekDayStyle(
            isToday: calendar.isDate(date, inSameDayAs: startOfToday),
            isPastOrToday: startOfDate <= startOfToday
        )
    }
}
