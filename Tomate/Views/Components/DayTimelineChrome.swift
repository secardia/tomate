import SwiftUI

struct DayTimelineChrome: View {
    let persistedTimeline: [TimelineInterval]
    let selectedDate: Date
    @Bindable var timer: PomodoroTimer

    private var calendar: Calendar { StatsCalendar.stats }

    private var timelineContext: DayTimelineLiveContext {
        StatsLiveSnapshot.dayTimelineContext(
            persistedTimeline: persistedTimeline,
            timer: timer,
            selectedDate: selectedDate,
            calendar: calendar
        )
    }

    private var chromeHeight: CGFloat {
        if timelineContext.showsLabels {
            return TimelineTimeLabelLayout.fontSize + 4 + AppLayoutMetrics.progressBarHeight
        }
        return AppLayoutMetrics.progressBarHeight
    }

    var body: some View {
        EdgeChrome {
            GeometryReader { geometry in
                let layout = DayTimelineLayout.make(
                    persistedTimeline: persistedTimeline,
                    liveTimeline: timelineContext.liveTimeline,
                    selectedDate: selectedDate,
                    calendar: calendar,
                    focusDurationSeconds: timer.configuration.focusDurationSeconds,
                    totalWidth: geometry.size.width
                )

                VStack(spacing: 0) {
                    if layout.showsLabels {
                        DayTimelineLabels(layout: layout)
                        Spacer().frame(height: 4)
                    }
                    DayTimelineBar(layout: layout)
                }
                .frame(width: geometry.size.width)
            }
            .frame(height: chromeHeight)
        }
    }
}
