import Foundation

struct TimelinePauseGap: Equatable {
    let start: Date
    let end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

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

    static func relativeFraction(for date: Date, in range: (start: Date, end: Date)) -> CGFloat? {
        let total = range.end.timeIntervalSince(range.start)
        guard total > 0 else { return nil }
        return CGFloat(date.timeIntervalSince(range.start) / total)
    }

    static func focusSumInMergedBlock(
        endingAt index: Int,
        in intervals: [TimelineInterval],
        minimumConnectingGap: TimeInterval
    ) -> TimeInterval {
        guard index >= 0, index < intervals.count else { return 0 }
        var sum: TimeInterval = 0
        var j = index
        while j >= 0 {
            if intervals[j].kind == .focus {
                sum += intervals[j].duration
            }
            if j == 0 { break }
            let gap = intervals[j].startDate.timeIntervalSince(intervals[j - 1].endDate)
            if gap >= minimumConnectingGap { break }
            j -= 1
        }
        return sum
    }

    static func focusSumInMergedBlock(
        startingAt index: Int,
        in intervals: [TimelineInterval],
        minimumConnectingGap: TimeInterval
    ) -> TimeInterval {
        guard index >= 0, index < intervals.count else { return 0 }
        var sum: TimeInterval = 0
        var j = index
        while j < intervals.count {
            if intervals[j].kind == .focus {
                sum += intervals[j].duration
            }
            if j == intervals.count - 1 { break }
            let gap = intervals[j + 1].startDate.timeIntervalSince(intervals[j].endDate)
            if gap >= minimumConnectingGap { break }
            j += 1
        }
        return sum
    }

    static func qualifyingPauseGap(
        in intervals: [TimelineInterval],
        completeFocusDuration: TimeInterval,
        minimumGap: TimeInterval
    ) -> TimelinePauseGap? {
        let sorted = intervals.sorted { $0.startDate < $1.startDate }
        guard sorted.count >= 2 else { return nil }

        var candidates: [TimelinePauseGap] = []
        for index in 0..<(sorted.count - 1) {
            let gapStart = sorted[index].endDate
            let gapEnd = sorted[index + 1].startDate
            let gapDuration = gapEnd.timeIntervalSince(gapStart)
            guard gapDuration >= minimumGap else { continue }

            let beforeFocus = focusSumInMergedBlock(
                endingAt: index,
                in: sorted,
                minimumConnectingGap: minimumGap
            )
            guard beforeFocus >= completeFocusDuration else { continue }

            let afterFocus = focusSumInMergedBlock(
                startingAt: index + 1,
                in: sorted,
                minimumConnectingGap: minimumGap
            )
            guard afterFocus >= completeFocusDuration else { continue }

            candidates.append(TimelinePauseGap(start: gapStart, end: gapEnd))
        }

        return candidates.max(by: { lhs, rhs in
            if lhs.duration != rhs.duration {
                return lhs.duration < rhs.duration
            }
            return lhs.start > rhs.start
        })
    }
}
