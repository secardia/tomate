import XCTest
@testable import Tomate

/// Scénarios complets : actions → graphe · cumul durée · compteur phases.
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
        AppPreferences.register()
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

    // MARK: - Passer focus

    func testScenarioPassFocus2Seconds() {
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPasser(at: t0.addingTimeInterval(2))

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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPasser(at: t0.addingTimeInterval(3))

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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPasser(at: t0.addingTimeInterval(1))

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

    // MARK: - Pause chrono → deux sessions focus

    func testScenarioPauseResumeThenPass() {
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(2))
        scenario.harness.tapReprendre(at: t0.addingTimeInterval(5))
        scenario.harness.tapPasser(at: t0.addingTimeInterval(7))

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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(2))
        scenario.harness.tapReprendre(at: t0.addingTimeInterval(3))
        scenario.harness.tapPasser(at: t0.addingTimeInterval(5))

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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(5))
        scenario.harness.tapReprendre(at: t0.addingTimeInterval(8))
        scenario.harness.tapPasser(at: t0.addingTimeInterval(9))

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

    // MARK: - Live figé pendant pause

    func testScenarioWhilePausedLiveGraphFrozen() {
        scenario.harness.tapReprendre(at: t0)
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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(2))
        scenario.harness.tapReprendre(at: t0.addingTimeInterval(12))
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
        scenario.harness.tapReprendre(at: t0)
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

    // MARK: - Réinitialiser

    func testScenarioReinitWhilePaused() {
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(3))
        scenario.harness.tapReinitialiser(at: t0.addingTimeInterval(13))

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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapReinitialiser(at: t0.addingTimeInterval(2))

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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(5))
        scenario.harness.tapReprendre(at: t0.addingTimeInterval(8))
        scenario.harness.tapReinitialiser(at: t0.addingTimeInterval(9))

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

    // MARK: - Focus puis calm

    func testScenarioFocusThenCalmShortRest() {
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPasser(at: t0.addingTimeInterval(3))
        scenario.harness.tapPasser(at: t0.addingTimeInterval(5)) // 2 s calm

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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPasser(at: t0.addingTimeInterval(3))
        scenario.harness.tapPasser(at: t0.addingTimeInterval(6)) // 3 s calm

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

    // MARK: - Règle save direct vs lance chrono

    func testScenarioReprendreDoesNotSaveUntilPausePassOrReinit() {
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(10))

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.timelineIntervals.count, 1)
        XCTAssertEqual(store.sessions[0].duration, 10, accuracy: 0.001)

        scenario.harness.tapReprendre(at: t0.addingTimeInterval(13))
        let observeAt = t0.addingTimeInterval(20)

        XCTAssertEqual(store.sessions.count, 1, "Reprendre ne save pas")
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

    // MARK: - Live avant enregistrement

    func testScenarioLiveGraphBeforePass() {
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(10))
        scenario.harness.tapReprendre(at: t0.addingTimeInterval(13))
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
        scenario.harness.tapReprendre(at: t0)
        scenario.harness.tapPause(at: t0.addingTimeInterval(3))
        scenario.harness.tapReprendre(at: t0.addingTimeInterval(6))
        scenario.harness.tapPasser(at: t0.addingTimeInterval(9))
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

    // MARK: - Rien enregistré

    func testScenarioPassWithZeroActiveRecordsNothing() {
        scenario.harness.tapPasser(at: t0)

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
        scenario.harness.tapReinitialiser(at: t0)

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
