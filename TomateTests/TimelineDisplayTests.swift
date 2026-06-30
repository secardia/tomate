import XCTest
@testable import Tomate

final class TimelineDisplayTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private let focusDuration: TimeInterval = 25 * 60
    private let minimumPauseGap = TimerConfiguration.minimumTimelinePauseGap

    private func interval(
        kind: TimelineIntervalKind,
        start: Date,
        duration: TimeInterval
    ) -> TimelineInterval {
        TimelineInterval(
            id: UUID(),
            kind: kind,
            startDate: start,
            endDate: start.addingTimeInterval(duration)
        )
    }

    // MARK: - qualifyingPauseGap

    func testQualifyingPauseGapPicksLongestPause() {
        let focus2h: TimeInterval = 2 * 60 * 60
        let pause1h: TimeInterval = 60 * 60
        let pause1h05: TimeInterval = 65 * 60
        let focus1h: TimeInterval = 60 * 60

        let intervals = [
            interval(kind: .focus, start: t0, duration: focus2h),
            interval(kind: .focus, start: t0.addingTimeInterval(focus2h + pause1h), duration: focus2h),
            interval(
                kind: .focus,
                start: t0.addingTimeInterval(focus2h + pause1h + focus2h + pause1h05),
                duration: focus1h
            ),
        ]

        let gap = TimelineDisplay.qualifyingPauseGap(
            in: intervals,
            completeFocusDuration: focusDuration,
            minimumGap: minimumPauseGap
        )

        XCTAssertNotNil(gap)
        XCTAssertEqual(gap!.duration, pause1h05, accuracy: 0.001)
        XCTAssertEqual(gap!.start, intervals[1].endDate)
        XCTAssertEqual(gap!.end, intervals[2].startDate)
    }

    func testQualifyingPauseGapTieBreaksToFirstPause() {
        let focus2h: TimeInterval = 2 * 60 * 60
        let pause1h: TimeInterval = 60 * 60

        let intervals = [
            interval(kind: .focus, start: t0, duration: focus2h),
            interval(kind: .focus, start: t0.addingTimeInterval(focus2h + pause1h), duration: focus2h),
            interval(
                kind: .focus,
                start: t0.addingTimeInterval(focus2h + pause1h + focus2h + pause1h),
                duration: focus2h
            ),
        ]

        let gap = TimelineDisplay.qualifyingPauseGap(
            in: intervals,
            completeFocusDuration: focusDuration,
            minimumGap: minimumPauseGap
        )

        XCTAssertNotNil(gap)
        XCTAssertEqual(gap!.duration, pause1h, accuracy: 0.001)
        XCTAssertEqual(gap!.start, intervals[0].endDate)
        XCTAssertEqual(gap!.end, intervals[1].startDate)
    }

    func testQualifyingPauseGapIgnoresShortGap() {
        let focus25m: TimeInterval = 25 * 60
        let pause10m: TimeInterval = 10 * 60

        let intervals = [
            interval(kind: .focus, start: t0, duration: focus25m),
            interval(kind: .focus, start: t0.addingTimeInterval(focus25m + pause10m), duration: focus25m),
        ]

        let gap = TimelineDisplay.qualifyingPauseGap(
            in: intervals,
            completeFocusDuration: focusDuration,
            minimumGap: minimumPauseGap
        )

        XCTAssertNil(gap)
    }

    func testQualifyingPauseGapIgnoresWhenBeforeBlockFocusTooShort() {
        let focus10m: TimeInterval = 10 * 60
        let rest5m: TimeInterval = 5 * 60
        let pause25m: TimeInterval = 25 * 60
        let focus25m: TimeInterval = 25 * 60

        let intervals = [
            interval(kind: .focus, start: t0, duration: focus10m),
            interval(kind: .rest, start: t0.addingTimeInterval(focus10m), duration: rest5m),
            interval(
                kind: .focus,
                start: t0.addingTimeInterval(focus10m + rest5m + pause25m),
                duration: focus25m
            ),
        ]

        let gap = TimelineDisplay.qualifyingPauseGap(
            in: intervals,
            completeFocusDuration: focusDuration,
            minimumGap: minimumPauseGap
        )

        XCTAssertNil(gap)
    }

    func testQualifyingPauseGapQualifiesMergedFocusBlockBeforePause() {
        let focus25m: TimeInterval = 25 * 60
        let rest5m: TimeInterval = 5 * 60
        let focus10m: TimeInterval = 10 * 60
        let pause30m: TimeInterval = 30 * 60

        let afterRest = t0.addingTimeInterval(focus25m + rest5m)
        let afterPause = afterRest.addingTimeInterval(focus10m + pause30m)

        let intervals = [
            interval(kind: .focus, start: t0, duration: focus25m),
            interval(kind: .rest, start: t0.addingTimeInterval(focus25m), duration: rest5m),
            interval(kind: .focus, start: afterRest, duration: focus10m),
            interval(kind: .focus, start: afterPause, duration: focus25m),
        ]

        let gap = TimelineDisplay.qualifyingPauseGap(
            in: intervals,
            completeFocusDuration: focusDuration,
            minimumGap: minimumPauseGap
        )

        XCTAssertNotNil(gap)
        XCTAssertEqual(gap!.start, intervals[2].endDate)
        XCTAssertEqual(gap!.end, intervals[3].startDate)
    }

    func testQualifyingPauseGapMergesShortTimerPausesIntoWorkBlock() {
        let focus25m: TimeInterval = 25 * 60
        let shortPause5m: TimeInterval = 5 * 60
        let lunch45m: TimeInterval = 45 * 60

        let secondFocusStart = t0.addingTimeInterval(focus25m + shortPause5m)
        let thirdFocusStart = secondFocusStart.addingTimeInterval(focus25m + lunch45m)

        let intervals = [
            interval(kind: .focus, start: t0, duration: focus25m),
            interval(kind: .focus, start: secondFocusStart, duration: focus25m),
            interval(kind: .focus, start: thirdFocusStart, duration: focus25m),
        ]

        let gap = TimelineDisplay.qualifyingPauseGap(
            in: intervals,
            completeFocusDuration: focusDuration,
            minimumGap: minimumPauseGap
        )

        XCTAssertNotNil(gap)
        XCTAssertEqual(gap!.duration, lunch45m, accuracy: 0.001)
        XCTAssertEqual(gap!.start, intervals[1].endDate)
        XCTAssertEqual(gap!.end, intervals[2].startDate)
    }

    // MARK: - relativeFraction

    func testRelativeFractionMapsDateWithinRange() {
        let range = (start: t0, end: t0.addingTimeInterval(100))
        let fraction = TimelineDisplay.relativeFraction(for: t0.addingTimeInterval(25), in: range)

        XCTAssertEqual(Double(fraction ?? 0), 0.25, accuracy: 0.001)
    }
}
