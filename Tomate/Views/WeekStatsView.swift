import SwiftUI

struct WeekStatsView: View {
    let store: SessionStore
    @Bindable var timer: PomodoroTimer
    @Binding var selectedDate: Date

    private var calendar: Calendar { StatsCalendar.stats }

    private var startOfToday: Date {
        calendar.startOfDay(for: Date())
    }

    private func isPastOrToday(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) <= startOfToday
    }

    var body: some View {
        let summary = StatsLiveSnapshot.weekSummary(
            store: store,
            timer: timer,
            selectedDate: selectedDate,
            calendar: calendar
        )

        HStack(spacing: 0) {
            ForEach(Array(summary.days.enumerated()), id: \.offset) { index, day in
                if index > 0 {
                    Rectangle()
                        .fill(AppColors.divider)
                        .frame(width: 1)
                        .padding(.top, 12)
                }
                WeekDayColumn(
                    focusCount: day.focusCount,
                    restCount: day.restCount,
                    dayLabel: StatsDateFormatter.shortWeekday(day.date),
                    isToday: calendar.isDateInToday(day.date),
                    isPastOrToday: isPastOrToday(day.date)
                )
            }
        }
        .frame(maxWidth: 420, minHeight: 100, maxHeight: 120)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}
