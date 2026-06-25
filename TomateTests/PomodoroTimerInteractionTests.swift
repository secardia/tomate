import XCTest
@testable import Tomate

final class PomodoroTimerInteractionTests: XCTestCase {
    private var store: SessionStore!
    private var timer: PomodoroTimer!
    private var harness: TimerTestHarness!

    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    private var testConfiguration: TimerConfiguration {
        TimerConfiguration(
            focusDurationSeconds: 5,
            restDurationSeconds: 2,
            autoStartBreaks: false,
            minimumSessionCountSeconds: 3
        )
    }

    private func daySummary() -> DaySummary {
        store.daySummary(
            for: t0,
            calendar: StatsCalendar.french,
            minimumSessionCountSeconds: testConfiguration.minimumSessionCountSeconds
        )
    }

    override func setUp() {
        super.setUp()
        AppPreferences.register()

        store = SessionStore(persistence: PersistenceController.inMemory())
        timer = PomodoroTimer(recording: store, configuration: testConfiguration)
        harness = TimerTestHarness(timer: timer)
    }

    // MARK: - Enregistrement sans seuil (timeline + durée)

    func testPasserRecordsTimelineAndDurationEvenWhenShort() throws {
        harness.tapReprendre(at: t0)
        harness.tapPasser(at: t0.addingTimeInterval(2))

        let session = try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(session.duration, 2, accuracy: 0.001)
        XCTAssertEqual(store.timelineIntervals.count, 1)
        XCTAssertEqual(store.timelineIntervals[0].duration, 2, accuracy: 0.001)
        XCTAssertEqual(daySummary().focusDuration, 2, accuracy: 0.001)
        XCTAssertEqual(daySummary().focusCount, 0)
    }

    func testPasserIncrementsSessionCountWhenAboveMinimum() throws {
        harness.tapReprendre(at: t0)
        harness.tapPasser(at: t0.addingTimeInterval(3))

        let session = try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(session.duration, 3, accuracy: 0.001)
        XCTAssertEqual(daySummary().focusDuration, 3, accuracy: 0.001)
        XCTAssertEqual(daySummary().focusCount, 1)
    }

    func testPauseResumeCreatesTwoFocusSessions() throws {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(2))
        harness.tapReprendre(at: t0.addingTimeInterval(5)) // 3 s pause chrono
        harness.tapPasser(at: t0.addingTimeInterval(7))

        XCTAssertEqual(store.timelineIntervals.count, 2)
        XCTAssertEqual(store.timelineIntervals[0].kind, .focus)
        XCTAssertEqual(store.timelineIntervals[0].duration, 2, accuracy: 0.001)
        XCTAssertEqual(store.timelineIntervals[1].kind, .focus)
        XCTAssertEqual(store.timelineIntervals[1].duration, 2, accuracy: 0.001)

        XCTAssertEqual(store.sessions.count, 2)
        XCTAssertEqual(store.sessions[0].duration, 2, accuracy: 0.001)
        XCTAssertEqual(store.sessions[1].duration, 2, accuracy: 0.001)
        XCTAssertEqual(daySummary().focusDuration, 4, accuracy: 0.001)
        XCTAssertEqual(daySummary().focusCount, 0)
    }

    func testShortPauseCreatesTwoFocusSessions() throws {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(2))
        harness.tapReprendre(at: t0.addingTimeInterval(3)) // 1 s pause
        harness.tapPasser(at: t0.addingTimeInterval(5))

        XCTAssertEqual(store.timelineIntervals.count, 2)
        XCTAssertEqual(store.timelineIntervals[0].kind, .focus)
        XCTAssertEqual(store.timelineIntervals[1].kind, .focus)
        XCTAssertEqual(store.timelineIntervals[1].duration, 2, accuracy: 0.001)
    }

    func testPasserKeepsAllFocusSegmentsIncludingShortTrailing() throws {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(5))
        harness.tapReprendre(at: t0.addingTimeInterval(8))
        harness.tapPasser(at: t0.addingTimeInterval(9))

        XCTAssertEqual(store.timelineIntervals.count, 2)
        XCTAssertEqual(store.timelineIntervals[1].duration, 1, accuracy: 0.001)

        XCTAssertEqual(store.sessions.count, 2)
        XCTAssertEqual(store.sessions[0].duration, 5, accuracy: 0.001)
        XCTAssertEqual(store.sessions[1].duration, 1, accuracy: 0.001)
    }

    // MARK: - Pause / reset / completion

    func testReprendreStartsRunningCountdown() {
        harness.tapReprendre(at: t0)
        XCTAssertTrue(timer.isRunning)
        XCTAssertTrue(store.sessions.isEmpty)
    }

    func testPauseFreezesActiveElapsed() {
        harness.tapReprendre(at: t0)
        let pausedAt = t0.addingTimeInterval(2)
        harness.tapPause(at: pausedAt)

        XCTAssertEqual(timer.activeElapsed(at: pausedAt.addingTimeInterval(10)), 2, accuracy: 0.001)
        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions[0].duration, 2, accuracy: 0.001)
    }

    func testTimelineIntervalsFrozenWhilePaused() {
        harness.tapReprendre(at: t0)
        let pausedAt = t0.addingTimeInterval(2)
        harness.tapPause(at: pausedAt)

        let live = timer.timelineIntervals(at: pausedAt.addingTimeInterval(30))
        XCTAssertEqual(live.count, 0)
        XCTAssertEqual(store.timelineIntervals.count, 1)
        XCTAssertEqual(store.timelineIntervals[0].duration, 2, accuracy: 0.001)
        XCTAssertEqual(store.timelineIntervals[0].endDate, pausedAt)
    }

    func testReinitialiserRecordsProgressAndStaysOnSamePhase() throws {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(3))
        harness.tapReinitialiser(at: t0.addingTimeInterval(13))

        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(store.timelineIntervals.count, 1)
        XCTAssertEqual(store.timelineIntervals[0].kind, .focus)

        let session = try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(session.duration, 3, accuracy: 0.001)
    }

    func testResetTrimsNothingFromTimeline() throws {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(5))
        harness.tapReprendre(at: t0.addingTimeInterval(8))
        harness.tapReinitialiser(at: t0.addingTimeInterval(9))

        XCTAssertEqual(store.timelineIntervals.count, 2)
        XCTAssertEqual(store.sessions.count, 2)
        XCTAssertEqual(store.sessions[0].duration, 5, accuracy: 0.001)
        XCTAssertEqual(store.sessions[1].duration, 1, accuracy: 0.001)
    }

    func testPasserStartsRestEvenWhenAutoStartBreaksDisabled() {
        harness.tapReprendre(at: t0)
        harness.tapPasser(at: t0.addingTimeInterval(3))
        XCTAssertEqual(timer.phase, .rest)
        XCTAssertTrue(timer.isRunning)
    }

    func testPauseResumeTimelinePersistsOnNaturalCompletion() throws {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(2))
        harness.tapReprendre(at: t0.addingTimeInterval(12))
        harness.tickCompletion(at: t0.addingTimeInterval(15))

        XCTAssertEqual(store.timelineIntervals.count, 2)
        XCTAssertEqual(store.sessions.count, 2)
        XCTAssertEqual(store.sessions[0].duration, 2, accuracy: 0.001)
        XCTAssertEqual(store.sessions[1].duration, 3, accuracy: 0.001)
        XCTAssertEqual(daySummary().focusDuration, 5, accuracy: 0.001)
        XCTAssertEqual(daySummary().focusCount, 1)
    }

    func testCompletionTicksRecordSessionWithoutTimerChrome() throws {
        harness.tapReprendre(at: t0)
        harness.tickCompletion(at: t0.addingTimeInterval(5))

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(try XCTUnwrap(store.sessions.first).duration, 5, accuracy: 0.001)
    }

    func testPausedPhaseNeverRecordsUntilPasserOrCompletion() {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(2))
        harness.tickCompletion(at: t0.addingTimeInterval(20))
        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions[0].duration, 2, accuracy: 0.001)
    }

    func testSystemSleepPausesRunningTimer() {
        harness.tapReprendre(at: t0)
        harness.systemWillSleep(at: t0.addingTimeInterval(2))

        XCTAssertFalse(timer.isRunning)
        XCTAssertTrue(timer.isPaused)
        XCTAssertEqual(timer.remainingTime(at: t0.addingTimeInterval(10)), 3, accuracy: 0.001)
        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions[0].duration, 2, accuracy: 0.001)
    }

    func testSystemWakeResumesAfterSleepPause() {
        harness.tapReprendre(at: t0)
        harness.systemWillSleep(at: t0.addingTimeInterval(2))
        harness.systemDidWake(at: t0.addingTimeInterval(60))

        XCTAssertTrue(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
        XCTAssertEqual(timer.remainingTime(at: t0.addingTimeInterval(61)), 3, accuracy: 0.001)
    }

    func testSystemWakeDoesNotResumeManualPause() {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(2))
        harness.systemWillSleep(at: t0.addingTimeInterval(3))
        harness.systemDidWake(at: t0.addingTimeInterval(60))

        XCTAssertFalse(timer.isRunning)
        XCTAssertTrue(timer.isPaused)
    }

    func testSystemSleepIgnoredWhenIdle() {
        harness.systemWillSleep(at: t0)
        harness.systemDidWake(at: t0.addingTimeInterval(60))

        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
    }

    func testAppQuitResetsLikeReinitialiser() throws {
        harness.tapReprendre(at: t0)
        harness.tapPause(at: t0.addingTimeInterval(3))
        harness.appWillTerminate(at: t0.addingTimeInterval(5))

        XCTAssertEqual(timer.phase, .focus)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
        XCTAssertEqual(timer.remainingTime(at: t0.addingTimeInterval(10)), 5, accuracy: 0.001)

        let session = try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(session.duration, 3, accuracy: 0.001)
    }
}
