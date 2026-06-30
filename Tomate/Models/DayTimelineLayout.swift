import Foundation

struct DayTimelineBarSegment: Identifiable, Equatable {
    let id: UUID
    let kind: TimelineIntervalKind
    let offsetX: CGFloat
    let width: CGFloat
}

struct DayTimelineLayout {
    let displayIntervals: [TimelineInterval]
    let range: (start: Date, end: Date)?
    let pauseGap: TimelinePauseGap?
    let inset: CGFloat
    let contentWidth: CGFloat
    let totalWidth: CGFloat

    var showsLabels: Bool { range != nil }

    static func make(
        persistedTimeline: [TimelineInterval],
        liveTimeline: [TimelineInterval],
        selectedDate: Date,
        calendar: Calendar,
        focusDurationSeconds: Int,
        minimumPauseGapSeconds: Int,
        totalWidth: CGFloat
    ) -> DayTimelineLayout {
        let displayIntervals = TimelineDisplay.displayIntervals(
            persisted: persistedTimeline,
            live: liveTimeline,
            selectedDate: selectedDate,
            calendar: calendar
        )
        let range = TimelineDisplay.range(for: displayIntervals)
        let inset = totalWidth * AppLayoutMetrics.timelineContentInsetFraction
        let contentWidth = max(0, totalWidth - 2 * inset)
        let pauseGap = range.map { _ in
            TimelineDisplay.qualifyingPauseGap(
                in: displayIntervals,
                completeFocusDuration: TimeInterval(focusDurationSeconds),
                minimumGap: TimeInterval(minimumPauseGapSeconds)
            )
        } ?? nil

        return DayTimelineLayout(
            displayIntervals: displayIntervals,
            range: range,
            pauseGap: pauseGap,
            inset: inset,
            contentWidth: contentWidth,
            totalWidth: totalWidth
        )
    }

    func timelineX(for date: Date) -> CGFloat {
        guard let range,
              let fraction = TimelineDisplay.relativeFraction(for: date, in: range) else {
            return inset
        }
        return inset + fraction * contentWidth
    }

    func barSegments() -> [DayTimelineBarSegment] {
        guard let range, contentWidth > 0 else { return [] }

        let total = range.end.timeIntervalSince(range.start)
        guard total > 0 else { return [] }

        return displayIntervals.map { interval in
            let relativeStart = interval.startDate.timeIntervalSince(range.start) / total
            let relativeWidth = interval.duration / total
            return DayTimelineBarSegment(
                id: interval.id,
                kind: interval.kind,
                offsetX: inset + CGFloat(relativeStart) * contentWidth,
                width: max(1, CGFloat(relativeWidth) * contentWidth)
            )
        }
    }

    func labelSpecs() -> [TimelineTimeLabelSpec] {
        guard let range else { return [] }

        var specs = [
            TimelineTimeLabelSpec(
                id: "dayStart",
                text: TimeFormatter.hourMinute(range.start),
                idealCenterX: timelineX(for: range.start)
            ),
            TimelineTimeLabelSpec(
                id: "dayEnd",
                text: TimeFormatter.hourMinute(range.end),
                idealCenterX: timelineX(for: range.end)
            ),
        ]

        if let pauseGap {
            specs.append(
                TimelineTimeLabelSpec(
                    id: "pauseStart",
                    text: TimeFormatter.hourMinute(pauseGap.start),
                    idealCenterX: timelineX(for: pauseGap.start)
                )
            )
            specs.append(
                TimelineTimeLabelSpec(
                    id: "pauseEnd",
                    text: TimeFormatter.hourMinute(pauseGap.end),
                    idealCenterX: timelineX(for: pauseGap.end)
                )
            )
        }

        return specs
    }

    func labelPlacements() -> [TimelineTimeLabelPlacement] {
        TimelineTimeLabelLayout.resolve(
            labels: labelSpecs(),
            availableWidth: totalWidth,
            horizontalPadding: AppLayoutMetrics.topBarMargin
        )
    }
}
