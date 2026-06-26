import SwiftUI

/// Day stat columns: persisted sessions + in-progress active time for durations; counts are persisted-only.
struct DayStatsView: View {
    let store: SessionStore
    @Bindable var timer: PomodoroTimer
    @Binding var selectedDate: Date

    private var calendar: Calendar { StatsCalendar.stats }

    var body: some View {
        let now = timer.timelineDisplayDate(at: timer.displayNow)
        let live = timer.liveActiveDuration(at: now, selectedDate: selectedDate, calendar: calendar)
        let summary = store.daySummary(
            for: selectedDate,
            calendar: calendar,
            liveFocusDuration: live.focus,
            liveRestDuration: live.rest
        )

        if summary.focusDuration > 0 || summary.restDuration > 0 {
            HStack(alignment: .top, spacing: 24) {
                DayStatColumn(
                    title: AppStrings.Stats.sessions,
                    count: summary.focusCount,
                    duration: DurationFormatter.clockDuration(summary.focusDuration),
                    accent: AppColors.focus
                )

                DayStatColumn(
                    title: AppStrings.Stats.pauses,
                    count: summary.restCount,
                    duration: DurationFormatter.clockDuration(summary.restDuration),
                    accent: AppColors.rest
                )
            }
            .frame(maxWidth: 280)
        }
    }
}
