import Foundation
import Observation

extension SessionStore: SessionRecording {}

@Observable
final class SessionStore {
    private(set) var sessions: [SessionRecord] = []
    private(set) var timelineIntervals: [TimelineInterval] = []

    private let persistence: any SessionPersistence
    private let calendar: Calendar
    /// Half-open interval `[loadedStart, loadedEnd)` currently held in memory.
    private var loadedStart: Date?
    private var loadedEnd: Date?

    init(
        persistence: any SessionPersistence = PersistenceController.shared,
        calendar: Calendar = StatsCalendar.stats
    ) {
        self.persistence = persistence
        self.calendar = calendar
        bootstrap()
    }

    func record(type: SessionType, start: Date, end: Date) {
        guard end > start else { return }
        let record = SessionRecord(id: UUID(), type: type, startDate: start, endDate: end)
        do {
            try persistence.insert(record)
            appendSessionIfNeeded(record)
        } catch {
            NSLog("SessionStore.record failed: \(error)")
        }
    }

    func recordTimeline(_ interval: TimelineInterval) {
        guard interval.endDate > interval.startDate else { return }
        do {
            try persistence.insertTimeline(interval)
            appendTimelineIfNeeded(interval)
        } catch {
            NSLog("SessionStore.recordTimeline failed: \(error)")
        }
    }

    /// Keeps the in-memory cache aligned with stats navigation.
    /// - Parameter shiftDirection: `+1` / `-1` when the user moved one week forward/back in week mode.
    func updateWindow(
        for selectedDate: Date,
        period: StatsPeriod,
        shiftDirection: Int = 0
    ) {
        if shiftDirection != 0, period == .week, let loadedStart, let loadedEnd {
            if shiftDirection > 0 {
                let range = SessionDataWindow.forwardPrefetchRange(from: loadedEnd, calendar: calendar)
                fetchRange(range.start, range.end)
            } else if shiftDirection < 0 {
                let range = SessionDataWindow.backwardPrefetchRange(before: loadedStart, calendar: calendar)
                fetchRange(range.start, range.end)
            }
        }

        let visible = SessionDataWindow.visibleRange(for: selectedDate, period: period, calendar: calendar)
        ensureRangeCovers(visible.start, visible.end)
    }

    func sessions(on date: Date, calendar: Calendar = .current) -> [SessionRecord] {
        sessions.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    func timeline(on date: Date, calendar: Calendar = .current) -> [TimelineInterval] {
        timelineIntervals.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    func sessions(inWeekContaining date: Date, calendar: Calendar = .current) -> [SessionRecord] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return sessions.filter { $0.startDate >= interval.start && $0.startDate < interval.end }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Aggregates persisted sessions plus optional in-progress active time (counts stay persisted-only).
    func daySummary(
        for date: Date,
        calendar: Calendar = .current,
        minimumSessionCountSeconds: Int = TimerConfiguration.defaultMinimumSessionCountSeconds,
        liveFocusDuration: TimeInterval = 0,
        liveRestDuration: TimeInterval = 0
    ) -> DaySummary {
        let daySessions = sessions(on: date, calendar: calendar)
        let focus = daySessions.filter { $0.type == .focus }
        let rest = daySessions.filter { $0.type == .rest }
        let minimum = TimeInterval(minimumSessionCountSeconds)
        return DaySummary(
            focusCount: focus.filter { $0.duration >= minimum }.count,
            restCount: rest.filter { $0.duration >= minimum }.count,
            focusDuration: focus.reduce(0) { $0 + $1.duration } + liveFocusDuration,
            restDuration: rest.reduce(0) { $0 + $1.duration } + liveRestDuration
        )
    }

    func weekSummary(
        for date: Date,
        calendar: Calendar = .current,
        minimumSessionCountSeconds: Int = TimerConfiguration.defaultMinimumSessionCountSeconds,
        liveForDate: Date? = nil,
        liveFocusDuration: TimeInterval = 0,
        liveRestDuration: TimeInterval = 0
    ) -> WeekSummary {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return WeekSummary(days: [], totalFocusDuration: 0)
        }

        let days = (0..<7).compactMap { offset -> DayWeekEntry? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let includesLive = liveForDate.map { calendar.isDate(day, inSameDayAs: $0) } ?? false
            let summary = daySummary(
                for: day,
                calendar: calendar,
                minimumSessionCountSeconds: minimumSessionCountSeconds,
                liveFocusDuration: includesLive ? liveFocusDuration : 0,
                liveRestDuration: includesLive ? liveRestDuration : 0
            )
            return DayWeekEntry(
                date: day,
                focusCount: summary.focusCount,
                restCount: summary.restCount,
                focusDuration: summary.focusDuration
            )
        }

        let totalFocus = days.reduce(0) { $0 + $1.focusDuration }
        return WeekSummary(days: days, totalFocusDuration: totalFocus)
    }

    // MARK: - Window management

    private func bootstrap() {
        do {
            try persistence.purgeLegacyIdleTimelineIntervals()
        } catch {
            NSLog("SessionStore.bootstrap purge failed: \(error)")
        }

        let initial = SessionDataWindow.initialRange(centeredOn: Date(), calendar: calendar)
        fetchRange(initial.start, initial.end)
    }

    private func ensureRangeCovers(_ start: Date, _ end: Date) {
        guard start < end else { return }

        if loadedStart == nil || loadedEnd == nil {
            let initial = SessionDataWindow.initialRange(centeredOn: Date(), calendar: calendar)
            fetchRange(initial.start, initial.end)
        }

        guard let loadedStart, let loadedEnd else { return }

        if start < loadedStart {
            fetchRange(start, loadedStart)
        }
        if end > loadedEnd {
            fetchRange(loadedEnd, end)
        }
    }

    private func fetchRange(_ start: Date, _ end: Date) {
        guard start < end else { return }

        do {
            let fetchedSessions = try persistence.fetchSessions(from: start, to: end)
            let fetchedIntervals = try persistence.fetchTimelineIntervals(from: start, to: end)
            mergeSessions(fetchedSessions)
            mergeTimelineIntervals(fetchedIntervals)
            extendLoadedRange(start: start, end: end)
        } catch {
            NSLog("SessionStore.fetchRange failed: \(error)")
        }
    }

    private func extendLoadedRange(start: Date, end: Date) {
        if let loadedStart {
            self.loadedStart = min(loadedStart, start)
        } else {
            loadedStart = start
        }

        if let loadedEnd {
            self.loadedEnd = max(loadedEnd, end)
        } else {
            loadedEnd = end
        }
    }

    private func mergeSessions(_ incoming: [SessionRecord]) {
        guard !incoming.isEmpty else { return }
        var known = Set(sessions.map(\.id))
        for record in incoming where known.insert(record.id).inserted {
            sessions.append(record)
        }
        sessions.sort { $0.startDate < $1.startDate }
    }

    private func mergeTimelineIntervals(_ incoming: [TimelineInterval]) {
        guard !incoming.isEmpty else { return }
        var known = Set(timelineIntervals.map(\.id))
        for interval in incoming where known.insert(interval.id).inserted {
            timelineIntervals.append(interval)
        }
        timelineIntervals.sort { $0.startDate < $1.startDate }
    }

    private func appendSessionIfNeeded(_ record: SessionRecord) {
        if let loadedStart, let loadedEnd,
           record.startDate >= loadedStart, record.startDate < loadedEnd {
            mergeSessions([record])
        } else {
            sessions.append(record)
            sessions.sort { $0.startDate < $1.startDate }
        }
    }

    private func appendTimelineIfNeeded(_ interval: TimelineInterval) {
        if let loadedStart, let loadedEnd,
           interval.startDate >= loadedStart, interval.startDate < loadedEnd {
            mergeTimelineIntervals([interval])
        } else {
            timelineIntervals.append(interval)
            timelineIntervals.sort { $0.startDate < $1.startDate }
        }
    }
}

#if DEBUG
extension SessionStore {
    /// Half-open loaded interval for unit tests.
    var loadedIntervalForTesting: (start: Date, end: Date)? {
        guard let loadedStart, let loadedEnd else { return nil }
        return (loadedStart, loadedEnd)
    }
}
#endif
