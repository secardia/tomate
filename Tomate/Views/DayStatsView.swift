import SwiftUI

/// Day stat columns: persisted sessions + in-progress active time for durations; counts are persisted-only.
struct DayStatsView: View {
    let store: SessionStore
    @Bindable var timer: PomodoroTimer
    @Binding var selectedDate: Date

    private var calendar: Calendar { StatsCalendar.stats }

    var body: some View {
        let summary = StatsLiveSnapshot.daySummary(
            store: store,
            timer: timer,
            selectedDate: selectedDate,
            calendar: calendar
        )

        if summary.focusDuration > 0 || summary.restDuration > 0 {
            HStack(alignment: .top, spacing: 24) {
                DayStatColumn(
                    title: AppStrings.Stats.sessions,
                    count: summary.focusCount,
                    duration: DurationFormatter.clockDuration(summary.focusDuration),
                    accent: SessionType.focus.accentColor
                )

                DayStatColumn(
                    title: AppStrings.Stats.pauses,
                    count: summary.restCount,
                    duration: DurationFormatter.clockDuration(summary.restDuration),
                    accent: SessionType.rest.accentColor
                )
            }
            .frame(maxWidth: 280)
        }
    }
}
