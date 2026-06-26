import Foundation

enum TimelineDisplay {
    static func displayIntervals(
        persisted: [TimelineInterval],
        live: [TimelineInterval],
        selectedDate: Date,
        calendar: Calendar = StatsCalendar.stats
    ) -> [TimelineInterval] {
        let merged = (persisted + live).sorted { $0.startDate < $1.startDate }
        return merged.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDate) }
    }

    static func range(for intervals: [TimelineInterval]) -> (start: Date, end: Date)? {
        guard let first = intervals.first?.startDate,
              let lastEnd = intervals.map(\.endDate).max(),
              lastEnd > first else { return nil }
        return (first, lastEnd)
    }
}
