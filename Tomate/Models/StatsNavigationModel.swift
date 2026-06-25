import Foundation
import Observation

@Observable
final class StatsNavigationModel {
    var screen: AppScreen = .timer
    var period: StatsPeriod = .day
    var selectedDate = Date()

    private let calendar: Calendar

    init(calendar: Calendar = StatsCalendar.french, selectedDate: Date = Date()) {
        self.calendar = calendar
        self.selectedDate = selectedDate
    }

    private(set) var dateShiftDirection: Int = 0

    func shiftDate(by value: Int) {
        dateShiftDirection = value
        let component: Calendar.Component = period == .day ? .day : .weekOfYear
        if let newDate = calendar.date(byAdding: component, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    func consumeDateShiftDirection() -> Int {
        defer { dateShiftDirection = 0 }
        return dateShiftDirection
    }

    func goToToday() {
        selectedDate = Date()
    }

    func tapTimer(resetTimer: () -> Void) {
        if screen == .timer {
            resetTimer()
        }
        screen = .timer
    }

    func tapStats() {
        screen = .stats
    }

    func statsNavigationTitle() -> String {
        switch period {
        case .day:
            StatsDateFormatter.dayTitle(selectedDate)
        case .week:
            StatsDateFormatter.weekTitle(containing: selectedDate, calendar: calendar)
        }
    }

    var showsTimerProgressChrome: Bool { screen == .timer }
    var showsDayTimelineBar: Bool { screen == .stats && period == .day }
}
