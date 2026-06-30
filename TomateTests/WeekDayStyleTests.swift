import XCTest
@testable import Tomate

final class WeekDayStyleTests: XCTestCase {
    private let timeZone = TimeZone(identifier: "Europe/Paris")!

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    func testPastDayIsNotToday() {
        let monday = date(year: 2026, month: 6, day: 22)
        let friday = date(year: 2026, month: 6, day: 26)

        let style = WeekDayStyle.make(date: monday, today: friday, calendar: calendar)

        XCTAssertTrue(style.isPastOrToday)
        XCTAssertFalse(style.isToday)
    }

    func testTodayIsHighlighted() {
        let friday = date(year: 2026, month: 6, day: 26)

        let style = WeekDayStyle.make(date: friday, today: friday, calendar: calendar)

        XCTAssertTrue(style.isPastOrToday)
        XCTAssertTrue(style.isToday)
    }

    func testFutureDayIsDimmed() {
        let saturday = date(year: 2026, month: 6, day: 27)
        let friday = date(year: 2026, month: 6, day: 26)

        let style = WeekDayStyle.make(date: saturday, today: friday, calendar: calendar)

        XCTAssertFalse(style.isPastOrToday)
        XCTAssertFalse(style.isToday)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(timeZone: timeZone, year: year, month: month, day: day, hour: 12))!
    }
}
