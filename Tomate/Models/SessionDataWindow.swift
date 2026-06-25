import Foundation

/// Date-range helpers for the in-memory session cache window.
enum SessionDataWindow {
    static let initialMonthOffset = 1
    static let prefetchWeekCount = 1

    /// Half-open interval `[start, end)` for the stats currently on screen.
    static func visibleRange(
        for date: Date,
        period: StatsPeriod,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        switch period {
        case .day:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
                let start = calendar.startOfDay(for: date)
                return (start, calendar.date(byAdding: .day, value: 1, to: start)!)
            }
            return (interval.start, interval.end)
        }
    }

    /// One calendar month before and after `center`, as a half-open day range.
    static func initialRange(
        centeredOn center: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let day = calendar.startOfDay(for: center)
        let start = calendar.date(byAdding: .month, value: -initialMonthOffset, to: day)!
        let lastIncluded = calendar.date(byAdding: .month, value: initialMonthOffset, to: day)!
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastIncluded))!
        return (start, end)
    }

    /// One week immediately after the current loaded window end.
    static func forwardPrefetchRange(
        from loadedEnd: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let end = calendar.date(byAdding: .weekOfYear, value: prefetchWeekCount, to: loadedEnd)!
        return (loadedEnd, end)
    }

    /// One week immediately before the current loaded window start.
    static func backwardPrefetchRange(
        before loadedStart: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let start = calendar.date(byAdding: .weekOfYear, value: -prefetchWeekCount, to: loadedStart)!
        return (start, loadedStart)
    }
}
