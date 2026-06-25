import XCTest
@testable import Tomate

final class SessionStoreWindowTests: XCTestCase {
    private var persistence: PersistenceController!
    private var store: SessionStore!
    private let calendar = StatsCalendar.french

    private let anchor = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        super.setUp()
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

    // MARK: - Helpers

    private func insertFocusSession(on date: Date, duration: TimeInterval) throws {
        let start = calendar.startOfDay(for: date).addingTimeInterval(3600)
        let record = SessionRecord(
            id: UUID(),
            type: .focus,
            startDate: start,
            endDate: start.addingTimeInterval(duration)
        )
        try persistence.insert(record)
    }
}
