import SwiftUI

struct DayTimelineBar: View {
    let persistedTimeline: [TimelineInterval]
    let selectedDate: Date
    @Bindable var timer: PomodoroTimer

    var body: some View {
        DayTimelineBarContent(
            persistedTimeline: persistedTimeline,
            selectedDate: selectedDate,
            timer: timer,
            now: timer.timelineDisplayDate(at: timer.displayNow)
        )
    }
}

private struct DayTimelineBarContent: View {
    let persistedTimeline: [TimelineInterval]
    let selectedDate: Date
    let timer: PomodoroTimer
    let now: Date

    private var calendar: Calendar { StatsCalendar.french }

    private var liveTimeline: [TimelineInterval] {
        guard calendar.isDate(selectedDate, inSameDayAs: now) else { return [] }
        return timer.timelineIntervals(at: now)
    }

    private var displayIntervals: [TimelineInterval] {
        TimelineDisplay.displayIntervals(
            persisted: persistedTimeline,
            live: liveTimeline,
            selectedDate: selectedDate,
            calendar: calendar
        )
    }

    private var timelineRange: (start: Date, end: Date)? {
        TimelineDisplay.range(for: displayIntervals)
    }

    var body: some View {
        VStack(spacing: 4) {
            if let timelineRange {
                HStack {
                    Text(timeLabel(timelineRange.start))
                    Spacer(minLength: 0)
                    Text(timeLabel(timelineRange.end))
                }
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppLayoutMetrics.topBarMargin)
            }

            timelineBar
        }
        .background(AppColors.background)
    }

    private var timelineBar: some View {
        GeometryReader { geometry in
            let inset = geometry.size.width * AppLayoutMetrics.timelineContentInsetFraction
            let contentWidth = max(0, geometry.size.width - 2 * inset)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppColors.timelineInactive)

                if let timelineRange, contentWidth > 0 {
                    ForEach(barSegments(in: timelineRange, contentInset: inset, contentWidth: contentWidth)) { segment in
                        Rectangle()
                            .fill(segment.color)
                            .frame(width: max(1, segment.width))
                            .offset(x: segment.offsetX)
                    }
                }
            }
        }
        .frame(height: AppLayoutMetrics.progressBarHeight)
    }

    private struct BarSegment: Identifiable {
        let id: UUID
        let offsetX: CGFloat
        let width: CGFloat
        let color: Color
    }

    private func barSegments(
        in range: (start: Date, end: Date),
        contentInset: CGFloat,
        contentWidth: CGFloat
    ) -> [BarSegment] {
        let total = range.end.timeIntervalSince(range.start)
        guard total > 0 else { return [] }

        return displayIntervals.map { interval in
            let relativeStart = interval.startDate.timeIntervalSince(range.start) / total
            let relativeWidth = interval.duration / total
            return BarSegment(
                id: interval.id,
                offsetX: contentInset + CGFloat(relativeStart) * contentWidth,
                width: max(1, CGFloat(relativeWidth) * contentWidth),
                color: color(for: interval.kind)
            )
        }
    }

    private func color(for kind: TimelineIntervalKind) -> Color {
        switch kind {
        case .focus: AppColors.focus
        case .rest: AppColors.rest
        }
    }

    private func timeLabel(_ date: Date) -> String {
        TimeFormatter.frenchHourMinute(date)
    }
}