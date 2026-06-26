import XCTest
@testable import Tomate

/// Full scenarios: actions → graph · cumulative duration · phase counts.
final class TimelineScenarioTests: XCTestCase {
    private var store: SessionStore!
    private var timer: PomodoroTimer!
    private var scenario: TimelineScenarioHarness!

    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    private var testConfiguration: TimerConfiguration {
        TimerConfiguration(
            focusDurationSeconds: 5,
            restDurationSeconds: 2,
            autoStartBreaks: false,
            minimumSessionCountSeconds: 3
        )
    }

    override func setUp() {
        super.setUp()
        TestPreferences.register()
        store = SessionStore(persistence: PersistenceController.inMemory())
        timer = PomodoroTimer(recording: store, configuration: testConfiguration)
        scenario = TimelineScenarioHarness(
            store: store,
            timer: timer,
            harness: TimerTestHarness(timer: timer),
            t0: t0,
            minimumSessionCountSeconds: testConfiguration.minimumSessionCountSeconds
        )
    }

    // MARK: - Skip focus

    func testScenarioPassFocus2Seconds() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapSkip(at: t0.addingTimeInterval(2))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 2)],
                displayTimeline: nil,
                focusDuration: 2,
                restDuration: 0,
                focusCount: 0,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: t0.addingTimeInterval(2)
        )
    }

    func testScenarioPassFocus3SecondsCountsSession() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapSkip(at: t0.addingTimeInterval(3))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 3)],
                displayTimeline: nil,
                focusDuration: 3,
                restDuration: 0,
                focusCount: 1,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: t0.addingTimeInterval(3)
        )
    }

    func testScenarioPassFocus1Second() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapSkip(at: t0.addingTimeInterval(1))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 1)],
                displayTimeline: nil,
                focusDuration: 1,
                restDuration: 0,
                focusCount: 0,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: t0.addingTimeInterval(1)
        )
    }

    // MARK: - Timer pause → two focus sessions

    func testScenarioPauseResumeThenPass() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(2))
        scenario.harness.tapStartOrResume(at: t0.addingTimeInterval(5))
        scenario.harness.tapSkip(at: t0.addingTimeInterval(7))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [
                    .init(kind: .focus, duration: 2),
                    .init(kind: .focus, duration: 2),
                ],
                displayTimeline: nil,
                focusDuration: 4,
                restDuration: 0,
                focusCount: 0,
                restCount: 0,
                sessionCount: 2
            ),
            observeAt: t0.addingTimeInterval(7)
        )
    }

    func testScenarioShortPauseStillShowsGray() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(2))
        scenario.harness.tapStartOrResume(at: t0.addingTimeInterval(3))
        scenario.harness.tapSkip(at: t0.addingTimeInterval(5))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [
                    .init(kind: .focus, duration: 2),
                    .init(kind: .focus, duration: 2),
                ],
                displayTimeline: nil,
                focusDuration: 4,
                restDuration: 0,
                focusCount: 0,
                restCount: 0,
                sessionCount: 2
            ),
            observeAt: t0.addingTimeInterval(5)
        )
    }

    func testScenarioKeepsShortTrailingFocusSegment() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(5))
        scenario.harness.tapStartOrResume(at: t0.addingTimeInterval(8))
        scenario.harness.tapSkip(at: t0.addingTimeInterval(9))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [
                    .init(kind: .focus, duration: 5),
                    .init(kind: .focus, duration: 1),
                ],
                displayTimeline: nil,
                focusDuration: 6,
                restDuration: 0,
                focusCount: 1,
                restCount: 0,
                sessionCount: 2
            ),
            observeAt: t0.addingTimeInterval(9)
        )
    }

    // MARK: - Live frozen while paused

    func testScenarioWhilePausedLiveGraphFrozen() {
        scenario.harness.tapStartOrResume(at: t0)
        let pausedAt = t0.addingTimeInterval(2)
        scenario.harness.tapPause(at: pausedAt)
        let observeAt = pausedAt.addingTimeInterval(30)

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 2)],
                displayTimeline: [.init(kind: .focus, duration: 2)],
                focusDuration: 2,
                restDuration: 0,
                focusCount: 0,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: observeAt
        )
    }

    // MARK: - Fin naturelle

    func testScenarioNaturalCompletionAfterPause() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(2))
        scenario.harness.tapStartOrResume(at: t0.addingTimeInterval(12))
        scenario.harness.tickCompletion(at: t0.addingTimeInterval(15))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [
                    .init(kind: .focus, duration: 2),
                    .init(kind: .focus, duration: 3),
                ],
                displayTimeline: nil,
                focusDuration: 5,
                restDuration: 0,
                focusCount: 1,
                restCount: 0,
                sessionCount: 2
            ),
            observeAt: t0.addingTimeInterval(15)
        )
    }

    func testScenarioNaturalCompletionSimple() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tickCompletion(at: t0.addingTimeInterval(5))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 5)],
                displayTimeline: nil,
                focusDuration: 5,
                restDuration: 0,
                focusCount: 1,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: t0.addingTimeInterval(5)
        )
    }

    // MARK: - Reset

    func testScenarioReinitWhilePaused() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(3))
        scenario.harness.tapReset(at: t0.addingTimeInterval(13))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 3)],
                displayTimeline: nil,
                focusDuration: 3,
                restDuration: 0,
                focusCount: 1,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: t0.addingTimeInterval(13)
        )
        XCTAssertEqual(timer.phase, .focus)
    }

    func testScenarioReinitShortFocus() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapReset(at: t0.addingTimeInterval(2))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 2)],
                displayTimeline: nil,
                focusDuration: 2,
                restDuration: 0,
                focusCount: 0,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: t0.addingTimeInterval(2)
        )
    }

    func testScenarioReinitAfterPauseResumeKeepsAllSegments() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(5))
        scenario.harness.tapStartOrResume(at: t0.addingTimeInterval(8))
        scenario.harness.tapReset(at: t0.addingTimeInterval(9))

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [
                    .init(kind: .focus, duration: 5),
                    .init(kind: .focus, duration: 1),
                ],
                displayTimeline: nil,
                focusDuration: 6,
                restDuration: 0,
                focusCount: 1,
                restCount: 0,
                sessionCount: 2
            ),
            observeAt: t0.addingTimeInterval(9)
        )
    }

    // MARK: - Focus then break

    func testScenarioFocusThenCalmShortRest() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapSkip(at: t0.addingTimeInterval(3))
        scenario.harness.tapSkip(at: t0.addingTimeInterval(5)) // 2 s break

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [
                    .init(kind: .focus, duration: 3),
                    .init(kind: .rest, duration: 2),
                ],
                displayTimeline: nil,
                focusDuration: 3,
                restDuration: 2,
                focusCount: 1,
                restCount: 0,
                sessionCount: 2
            ),
            observeAt: t0.addingTimeInterval(5)
        )
    }

    func testScenarioFocusThenCalmBothCount() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapSkip(at: t0.addingTimeInterval(3))
        scenario.harness.tapSkip(at: t0.addingTimeInterval(6)) // 3 s break

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [
                    .init(kind: .focus, duration: 3),
                    .init(kind: .rest, duration: 3),
                ],
                displayTimeline: nil,
                focusDuration: 3,
                restDuration: 3,
                focusCount: 1,
                restCount: 1,
                sessionCount: 2
            ),
            observeAt: t0.addingTimeInterval(6)
        )
    }

    // MARK: - Direct save vs start timer rule

    func testScenarioResumeDoesNotSaveUntilPauseSkipOrReset() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(10))

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.timelineIntervals.count, 1)
        XCTAssertEqual(store.sessions[0].duration, 10, accuracy: 0.001)

        scenario.harness.tapStartOrResume(at: t0.addingTimeInterval(13))
        let observeAt = t0.addingTimeInterval(20)

        XCTAssertEqual(store.sessions.count, 1, "Resume does not save")
        XCTAssertEqual(store.timelineIntervals.count, 1)

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 10)],
                displayTimeline: [
                    .init(kind: .focus, duration: 10),
                    .init(kind: .focus, duration: 7),
                ],
                focusDuration: 17,
                restDuration: 0,
                focusCount: 1,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: observeAt
        )
    }

    // MARK: - Live before recording

    func testScenarioLiveGraphBeforePass() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(10))
        scenario.harness.tapStartOrResume(at: t0.addingTimeInterval(13))
        let observeAt = t0.addingTimeInterval(28)

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [.init(kind: .focus, duration: 10)],
                displayTimeline: [
                    .init(kind: .focus, duration: 10),
                    .init(kind: .focus, duration: 15),
                ],
                focusDuration: 25,
                restDuration: 0,
                focusCount: 1,
                restCount: 0,
                sessionCount: 1
            ),
            observeAt: observeAt
        )
    }

    func testScenarioLiveGraphAfterPassWithCalmRunning() {
        scenario.harness.tapStartOrResume(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(3))
        scenario.harness.tapStartOrResume(at: t0.addingTimeInterval(6))
        scenario.harness.tapSkip(at: t0.addingTimeInterval(9))
        let observeAt = t0.addingTimeInterval(11)

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [
                    .init(kind: .focus, duration: 3),
                    .init(kind: .focus, duration: 3),
                ],
                displayTimeline: [
                    .init(kind: .focus, duration: 3),
                    .init(kind: .focus, duration: 3),
                    .init(kind: .rest, duration: 2),
                ],
                focusDuration: 6,
                restDuration: 2,
                focusCount: 2,
                restCount: 0,
                sessionCount: 2
            ),
            observeAt: observeAt
        )
    }

    // MARK: - Nothing recorded

    func testScenarioPassWithZeroActiveRecordsNothing() {
        scenario.harness.tapSkip(at: t0)

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [],
                displayTimeline: [],
                focusDuration: 0,
                restDuration: 0,
                focusCount: 0,
                restCount: 0,
                sessionCount: 0
            ),
            observeAt: t0
        )
    }

    func testScenarioResetWithoutProgressRecordsNothing() {
        scenario.harness.tapReset(at: t0)

        scenario.assertOutcome(
            TimelineScenarioExpectations(
                persistedTimeline: [],
                displayTimeline: [],
                focusDuration: 0,
                restDuration: 0,
                focusCount: 0,
                restCount: 0,
                sessionCount: 0
            ),
            observeAt: t0
        )
    }
}
