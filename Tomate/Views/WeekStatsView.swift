import SwiftUI

struct WeekStatsView: View {
    let store: SessionStore
    @Bindable var timer: PomodoroTimer
    @Binding var selectedDate: Date

    @Environment(\.statsToday) private var statsToday

    private var calendar: Calendar { StatsCalendar.stats }

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
                let style = WeekDayStyle.make(date: day.date, today: statsToday, calendar: calendar)
                WeekDayColumn(
                    focusCount: day.focusCount,
                    restCount: day.restCount,
                    dayLabel: StatsDateFormatter.shortWeekday(day.date),
                    isToday: style.isToday,
                    isPastOrToday: style.isPastOrToday
                )
            }
        }
        .frame(maxWidth: 420, minHeight: 100, maxHeight: 120)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}
