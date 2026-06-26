import XCTest
@testable import Tomate

final class SessionStoreWindowTests: XCTestCase {
    private var persistence: PersistenceController!
    private var store: SessionStore!
    private var calendar: Calendar!

    private let anchor = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        super.setUp()
        TestPreferences.register()
        calendar = StatsCalendar.stats
        persistence = PersistenceController.inMemory()
        store = SessionStore(persistence: persistence, calendar: calendar)
    }

    func testBootstrapLoadsOneMonthWindowAroundToday() throws {
        let interval = try XCTUnwrap(store.loadedIntervalForTesting)
        let expected = SessionDataWindow.initialRange(centeredOn: Date(), calendar: calendar)

        XCTAssertEqual(interval.start, expected.start)
        XCTAssertEqual(interval.end, expected.end)
    }

    func testSessionsOutsideInitialWindowAreNotCachedUntilRequested() throws {
        let distant = calendar.date(byAdding: .month, value: -6, to: anchor)!
        try insertFocusSession(on: distant, duration: 120)

        XCTAssertTrue(store.sessions.isEmpty)

        store.updateWindow(for: distant, period: .day)

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions[0].duration, 120, accuracy: 0.001)
    }

    func testWeekPrefetchExtendsWindowForward() throws {
        let interval = try XCTUnwrap(store.loadedIntervalForTesting)
        let prefetchDay = calendar.date(byAdding: .day, value: 3, to: interval.end)!

        try insertFocusSession(on: prefetchDay, duration: 90)

        XCTAssertTrue(store.sessions.isEmpty)

        store.updateWindow(for: anchor, period: .week, shiftDirection: 1)

        let extended = try XCTUnwrap(store.loadedIntervalForTesting)
        XCTAssertGreaterThanOrEqual(extended.end, calendar.date(byAdding: .weekOfYear, value: 1, to: interval.end)!)
        XCTAssertEqual(store.sessions.count, 1)
    }

    func testWeekPrefetchExtendsWindowBackward() throws {
        let interval = try XCTUnwrap(store.loadedIntervalForTesting)
        let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: interval.start)!

        try insertFocusSession(on: previousWeek, duration: 75)

        XCTAssertTrue(store.sessions.isEmpty)

        store.updateWindow(for: anchor, period: .week, shiftDirection: -1)

        let extended = try XCTUnwrap(store.loadedIntervalForTesting)
        XCTAssertLessThanOrEqual(extended.start, calendar.date(byAdding: .weekOfYear, value: -1, to: interval.start)!)
        XCTAssertEqual(store.sessions.count, 1)
    }

    func testVisibleWeekIsCoveredAfterJump() throws {
        let distantWeek = calendar.date(byAdding: .month, value: -4, to: anchor)!
        try insertFocusSession(on: distantWeek, duration: 180)

        store.updateWindow(for: distantWeek, period: .week)

        XCTAssertEqual(store.weekSummary(for: distantWeek, calendar: calendar).totalFocusDuration, 180, accuracy: 0.001)
    }

    func testLiveRecordAppendsEvenWhenOutsideLoadedWindow() throws {
        let distant = calendar.date(byAdding: .year, value: -2, to: anchor)!
        store.record(type: .focus, start: distant, end: distant.addingTimeInterval(30))

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions[0].duration, 30, accuracy: 0.001)
    }

    func testWeekSummaryTotalsWednesdayThroughTuesdayWhenWednesdayIsFirstWeekday() throws {
        var wednesdayFirst = Calendar(identifier: .gregorian)
        wednesdayFirst.timeZone = TimeZone(identifier: "UTC")!
        wednesdayFirst.firstWeekday = 4

        let persistence = PersistenceController.inMemory()
        let store = SessionStore(persistence: persistence, calendar: wednesdayFirst)

        var components = DateComponents()
        components.timeZone = wednesdayFirst.timeZone
        components.year = 2026
        components.month = 6
        components.day = 26
        components.hour = 12
        let fridayInWeek = try XCTUnwrap(wednesdayFirst.date(from: components))

        let weekStart = try XCTUnwrap(wednesdayFirst.dateInterval(of: .weekOfYear, for: fridayInWeek)?.start)
        let wednesday = weekStart
        let tuesdayEnd = try XCTUnwrap(wednesdayFirst.date(byAdding: .day, value: 6, to: weekStart))
        let tuesdayBefore = try XCTUnwrap(wednesdayFirst.date(byAdding: .day, value: -1, to: weekStart))

        XCTAssertEqual(wednesdayFirst.component(.weekday, from: wednesday), 4)
        XCTAssertEqual(wednesdayFirst.component(.weekday, from: tuesdayEnd), 3)
        XCTAssertFalse(
            wednesdayFirst.dateInterval(of: .weekOfYear, for: fridayInWeek)!.contains(tuesdayBefore)
        )

        recordFocus(on: wednesday, duration: 50, store: store, calendar: wednesdayFirst)
        recordFocus(on: tuesdayEnd, duration: 100, store: store, calendar: wednesdayFirst)
        recordFocus(on: tuesdayBefore, duration: 999, store: store, calendar: wednesdayFirst)

        store.updateWindow(for: fridayInWeek, period: .week)

        let summary = store.weekSummary(for: fridayInWeek, calendar: wednesdayFirst)
        XCTAssertEqual(summary.totalFocusDuration, 150, accuracy: 0.001)
        XCTAssertEqual(summary.days.count, 7)
        XCTAssertEqual(wednesdayFirst.component(.weekday, from: summary.days[0].date), 4)
        XCTAssertEqual(wednesdayFirst.component(.weekday, from: summary.days[6].date), 3)
        XCTAssertEqual(store.sessions(inWeekContaining: fridayInWeek, calendar: wednesdayFirst).count, 2)
    }

    // MARK: - Helpers

    private func insertFocusSession(
        on date: Date,
        duration: TimeInterval,
        persistence: PersistenceController? = nil,
        calendar: Calendar? = nil
    ) throws {
        let persistence = persistence ?? self.persistence!
        let calendar = calendar ?? self.calendar!
        let start = calendar.startOfDay(for: date).addingTimeInterval(3600)
        let record = SessionRecord(
            id: UUID(),
            type: .focus,
            startDate: start,
            endDate: start.addingTimeInterval(duration)
        )
        try persistence.insert(record)
    }

    private func recordFocus(
        on date: Date,
        duration: TimeInterval,
        store: SessionStore,
        calendar: Calendar
    ) {
        let start = calendar.startOfDay(for: date).addingTimeInterval(3600)
        store.record(type: .focus, start: start, end: start.addingTimeInterval(duration))
    }
}
