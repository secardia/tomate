import XCTest
@testable import Tomate

/// Expected outcome for a scenario: graph, cumulative duration, phase counts.
///
/// Recording rule:
/// - Start / Resume / Skip (phase start) → timer only, nothing in DB.
/// - Pause / Skip (end) / Reset → direct save (dates = current segment).
/// - Stats cumulative = persisted sessions + open live segment (not yet saved).
struct TimelineScenarioExpectations {
    struct SegmentSpec: Equatable {
        let kind: TimelineIntervalKind
        let duration: TimeInterval
    }

    let persistedTimeline: [SegmentSpec]
    /// Segments shown on the Day bar (persisted + live). Nil = same as persisted.
    let displayTimeline: [SegmentSpec]?
    let focusDuration: TimeInterval
    let restDuration: TimeInterval
    let focusCount: Int
    let restCount: Int
    let sessionCount: Int

    var displaySegments: [SegmentSpec] { displayTimeline ?? persistedTimeline }

    func assertTimeline(
        _ intervals: [TimelineInterval],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(intervals.count, persistedTimeline.count, file: file, line: line)
        for (index, spec) in persistedTimeline.enumerated() {
            XCTAssertEqual(intervals[index].kind, spec.kind, file: file, line: line)
            XCTAssertEqual(intervals[index].duration, spec.duration, accuracy: 0.001, file: file, line: line)
        }
    }

    func assertDisplayTimeline(
        _ intervals: [TimelineInterval],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expected = displaySegments
        XCTAssertEqual(intervals.count, expected.count, file: file, line: line)
        for (index, spec) in expected.enumerated() {
            XCTAssertEqual(intervals[index].kind, spec.kind, file: file, line: line)
            XCTAssertEqual(intervals[index].duration, spec.duration, accuracy: 0.001, file: file, line: line)
        }
    }

    func assertStats(
        _ summary: DaySummary,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(summary.focusDuration, focusDuration, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(summary.restDuration, restDuration, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(summary.focusCount, focusCount, file: file, line: line)
        XCTAssertEqual(summary.restCount, restCount, file: file, line: line)
    }

    func assertSessions(
        _ sessions: [SessionRecord],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(sessions.count, sessionCount, file: file, line: line)
    }
}

struct TimelineScenarioHarness {
    let store: SessionStore
    let timer: PomodoroTimer
    let harness: TimerTestHarness
    let t0: Date
    let minimumSessionCountSeconds: Int

    func daySummary(at now: Date, on date: Date? = nil) -> DaySummary {
        let day = date ?? t0
        let live = timer.liveActiveDuration(at: now, selectedDate: day, calendar: StatsCalendar.stats)
        return store.daySummary(
            for: day,
            calendar: StatsCalendar.stats,
            minimumSessionCountSeconds: minimumSessionCountSeconds,
            liveFocusDuration: live.focus,
            liveRestDuration: live.rest
        )
    }

    func displayTimeline(at now: Date, selectedDate: Date? = nil) -> [TimelineInterval] {
        let day = selectedDate ?? t0
        let reference = timer.timelineDisplayDate(at: now)
        let live = StatsCalendar.stats.isDate(day, inSameDayAs: reference)
            ? timer.timelineIntervals(at: reference)
            : []
        return TimelineDisplay.displayIntervals(
            persisted: store.timeline(on: day, calendar: StatsCalendar.stats),
            live: live,
            selectedDate: day,
            calendar: StatsCalendar.stats
        )
    }

    func assertOutcome(
        _ expected: TimelineScenarioExpectations,
        observeAt: Date,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expected.assertTimeline(store.timelineIntervals, file: file, line: line)
        expected.assertDisplayTimeline(displayTimeline(at: observeAt), file: file, line: line)
        expected.assertStats(daySummary(at: observeAt), file: file, line: line)
        expected.assertSessions(store.sessions, file: file, line: line)
    }
}
