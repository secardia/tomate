import Foundation

struct LiveDurations: Equatable {
    let focus: TimeInterval
    let rest: TimeInterval
}

struct DayTimelineLiveContext {
    let now: Date
    let liveTimeline: [TimelineInterval]
    let displayIntervals: [TimelineInterval]

    var showsLabels: Bool {
        TimelineDisplay.range(for: displayIntervals) != nil
    }
}

enum StatsLiveSnapshot {
    static func referenceDate(timer: PomodoroTimer, at date: Date) -> Date {
        timer.timelineDisplayDate(at: date)
    }

    static func liveDurations(
        timer: PomodoroTimer,
        at now: Date,
        selectedDate: Date,
        calendar: Calendar = StatsCalendar.stats
    ) -> LiveDurations {
        let live = timer.liveActiveDuration(at: now, selectedDate: selectedDate, calendar: calendar)
        return LiveDurations(focus: live.focus, rest: live.rest)
    }

    static func daySummary(
        store: SessionStore,
        timer: PomodoroTimer,
        selectedDate: Date,
        calendar: Calendar = StatsCalendar.stats
    ) -> DaySummary {
        let now = referenceDate(timer: timer, at: timer.displayNow)
        let live = liveDurations(timer: timer, at: now, selectedDate: selectedDate, calendar: calendar)
        return store.daySummary(
            for: selectedDate,
            calendar: calendar,
            liveFocusDuration: live.focus,
            liveRestDuration: live.rest
        )
    }

    static func weekSummary(
        store: SessionStore,
        timer: PomodoroTimer,
        selectedDate: Date,
        calendar: Calendar = StatsCalendar.stats
    ) -> WeekSummary {
        let now = referenceDate(timer: timer, at: timer.displayNow)
        let live = liveDurations(timer: timer, at: now, selectedDate: now, calendar: calendar)
        return store.weekSummary(
            for: selectedDate,
            calendar: calendar,
            liveForDate: now,
            liveFocusDuration: live.focus,
            liveRestDuration: live.rest
        )
    }

    static func dayTimelineContext(
        persistedTimeline: [TimelineInterval],
        timer: PomodoroTimer,
        selectedDate: Date,
        calendar: Calendar = StatsCalendar.stats
    ) -> DayTimelineLiveContext {
        let now = referenceDate(timer: timer, at: timer.displayNow)
        let liveTimeline = calendar.isDate(selectedDate, inSameDayAs: now)
            ? timer.timelineIntervals(at: now)
            : []
        let displayIntervals = TimelineDisplay.displayIntervals(
            persisted: persistedTimeline,
            live: liveTimeline,
            selectedDate: selectedDate,
            calendar: calendar
        )
        return DayTimelineLiveContext(
            now: now,
            liveTimeline: liveTimeline,
            displayIntervals: displayIntervals
        )
    }
}
