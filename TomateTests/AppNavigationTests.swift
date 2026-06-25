import XCTest
@testable import Tomate

/// Wraps `StatsNavigationModel` plus display helpers used by navigation tests.
private struct AppNavigationHarness {
    var navigation: StatsNavigationModel

    let store: SessionStore
    let timer: PomodoroTimer
    let timerHarness: TimerTestHarness
    let calendar: Calendar

    init(store: SessionStore, timer: PomodoroTimer, selectedDate: Date) {
        self.store = store
        self.timer = timer
        self.timerHarness = TimerTestHarness(timer: timer)
        self.calendar = StatsCalendar.french
        self.navigation = StatsNavigationModel(calendar: StatsCalendar.french, selectedDate: selectedDate)
    }

    var selectedDate: Date {
        get { navigation.selectedDate }
        set { navigation.selectedDate = newValue }
    }

    // MARK: - Top toolbar (timer / stats icons)

    mutating func tapStatsIcon() {
        navigation.tapStats()
    }

    mutating func tapTimerIcon(at date: Date) {
        navigation.tapTimer { timerHarness.tapToolbarTimerReset(at: date) }
    }

    // MARK: - Stats period tabs (Jour / Semaine)

    mutating func tapJourTab() {
        navigation.period = .day
    }

    mutating func tapSemaineTab() {
        navigation.period = .week
    }

    // MARK: - Date navigator

    mutating func tapPrevious() {
        navigation.shiftDate(by: -1)
    }

    mutating func tapNext() {
        navigation.shiftDate(by: 1)
    }

    mutating func tapAujourdhui(to date: Date) {
        navigation.goToToday()
        navigation.selectedDate = date
    }

    // MARK: - Chrome visibility (RootView safeAreaInset rules)

    var showsTimerProgressChrome: Bool { navigation.showsTimerProgressChrome }
    var showsDayTimelineBar: Bool { navigation.showsDayTimelineBar }
    var showsWeekBottomChrome: Bool { navigation.screen == .stats && navigation.period == .week }
    var runsLiveDisplayPolling: Bool { timer.isRunning }

    // MARK: - Display data (what views read)

    func daySummary(at now: Date) -> DaySummary {
        let reference = timer.timelineDisplayDate(at: now)
        let live = timer.liveActiveDuration(at: reference, selectedDate: navigation.selectedDate, calendar: calendar)
        return store.daySummary(
            for: navigation.selectedDate,
            calendar: calendar,
            minimumSessionCountSeconds: timer.configuration.minimumSessionCountSeconds,
            liveFocusDuration: live.focus,
            liveRestDuration: live.rest
        )
    }

    func weekSummary() -> WeekSummary {
        store.weekSummary(
            for: navigation.selectedDate,
            calendar: calendar,
            minimumSessionCountSeconds: timer.configuration.minimumSessionCountSeconds
        )
    }

    func dayTimelineForSelectedDate() -> [TimelineInterval] {
        store.timeline(on: navigation.selectedDate, calendar: calendar)
    }

    func displayTimeline(at now: Date) -> [TimelineInterval] {
        let reference = timer.timelineDisplayDate(at: now)
        let live = calendar.isDate(navigation.selectedDate, inSameDayAs: reference)
            ? timer.timelineIntervals(at: reference)
            : []
        return TimelineDisplay.displayIntervals(
            persisted: dayTimelineForSelectedDate(),
            live: live,
            selectedDate: navigation.selectedDate,
            calendar: calendar
        )
    }

    func weekDayEntry(containing date: Date) -> DayWeekEntry? {
        weekSummary().days.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

final class AppNavigationTests: XCTestCase {
    private var store: SessionStore!
    private var timer: PomodoroTimer!
    private var nav: AppNavigationHarness!

    /// Anchor for the viewed day; all interactions happen the same calendar day.
    private var today: Date!

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

        today = Date()
        store = SessionStore(persistence: PersistenceController.inMemory())
        timer = PomodoroTimer(recording: store, configuration: testConfiguration)
        nav = AppNavigationHarness(store: store, timer: timer, selectedDate: today)
    }

    // MARK: - Navigation chrome

    func testTimerScreenShowsProgressChromeOnly() {
        XCTAssertTrue(nav.showsTimerProgressChrome)
        XCTAssertFalse(nav.showsDayTimelineBar)
        XCTAssertTrue(nav.runsLiveDisplayPolling == timer.isRunning)
    }

    func testStatsJourShowsTimelineNotProgressChrome() {
        nav.tapStatsIcon()
        nav.tapJourTab()

        XCTAssertFalse(nav.showsTimerProgressChrome)
        XCTAssertTrue(nav.showsDayTimelineBar)
        XCTAssertFalse(nav.showsWeekBottomChrome)
    }

    func testStatsSemaineHidesTimelineBar() {
        nav.tapStatsIcon()
        nav.tapSemaineTab()

        XCTAssertFalse(nav.showsTimerProgressChrome)
        XCTAssertFalse(nav.showsDayTimelineBar)
        XCTAssertTrue(nav.showsWeekBottomChrome)
    }

    func testSwitchingJourAndSemainePreservesRecordedSessions() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.timerHarness.tapPasser(at: today.addingTimeInterval(3))

        nav.tapStatsIcon()
        nav.tapJourTab()
        let afterPass = today.addingTimeInterval(3)
        XCTAssertEqual(nav.daySummary(at: afterPass).focusCount, 1)

        nav.tapSemaineTab()
        XCTAssertEqual(nav.weekSummary().totalFocusDuration, 3, accuracy: 0.001)

        nav.tapJourTab()
        XCTAssertEqual(nav.daySummary(at: afterPass).focusCount, 1)
    }

    // MARK: - Recording across screens

    func testCompleteFocusWhileOnStatsJourRecordsAndUpdatesDayView() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.tapStatsIcon()
        nav.tapJourTab()

        XCTAssertTrue(nav.runsLiveDisplayPolling)

        let completeAt = today.addingTimeInterval(5)
        nav.timerHarness.tickCompletion(at: completeAt)

        let summary = nav.daySummary(at: completeAt)
        XCTAssertEqual(summary.focusCount, 1)
        XCTAssertEqual(summary.focusDuration, 5, accuracy: 0.001)
        XCTAssertEqual(summary.restCount, 0)

        let weekDay = try XCTUnwrap(nav.weekDayEntry(containing: today))
        XCTAssertEqual(weekDay.focusCount, 1)
        XCTAssertEqual(weekDay.focusDuration, 5, accuracy: 0.001)
    }

    func testCompleteFocusWhileOnStatsSemaineRecordsWithoutTimeline() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.tapStatsIcon()
        nav.tapSemaineTab()

        XCTAssertFalse(nav.showsDayTimelineBar)
        XCTAssertTrue(nav.runsLiveDisplayPolling)

        nav.timerHarness.tickCompletion(at: today.addingTimeInterval(5))

        XCTAssertEqual(nav.weekSummary().totalFocusDuration, 5, accuracy: 0.001)
        XCTAssertEqual(nav.daySummary(at: today.addingTimeInterval(5)).focusCount, 1)
        XCTAssertNil(nav.displayTimeline(at: today.addingTimeInterval(5)).first { $0.kind == .rest })
    }

    func testJourToSemaineWhileRunningStillCompletes() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.tapStatsIcon()
        nav.tapJourTab()
        nav.tapSemaineTab()

        let completeAt = today.addingTimeInterval(5)
        nav.timerHarness.tickCompletion(at: completeAt)

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(nav.weekSummary().totalFocusDuration, 5, accuracy: 0.001)
    }

    // MARK: - Live timeline (Jour)

    func testLiveTimelineVisibleOnJourWhileRunningToday() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.tapStatsIcon()
        nav.tapJourTab()

        let runningAt = today.addingTimeInterval(2)
        let displayed = nav.displayTimeline(at: runningAt)

        XCTAssertEqual(displayed.count, 1)
        XCTAssertEqual(displayed[0].kind, .focus)
        XCTAssertEqual(displayed[0].duration, 2, accuracy: 0.001)
        XCTAssertEqual(displayed[0].endDate, runningAt)
    }

    func testLiveTimelineShowsFocusFrozenWhilePaused() throws {
        nav.timerHarness.tapReprendre(at: today)
        let pausedAt = today.addingTimeInterval(2)
        nav.timerHarness.tapPause(at: pausedAt)
        nav.tapStatsIcon()
        nav.tapJourTab()

        let later = pausedAt.addingTimeInterval(30)
        let displayed = nav.displayTimeline(at: later)

        XCTAssertEqual(displayed.count, 1)
        XCTAssertEqual(displayed[0].kind, .focus)
        XCTAssertEqual(displayed[0].duration, 2, accuracy: 0.001)
        XCTAssertEqual(displayed[0].endDate, pausedAt)
        XCTAssertEqual(nav.daySummary(at: later).focusCount, 0)
        XCTAssertEqual(nav.daySummary(at: later).focusDuration, 2, accuracy: 0.001)
    }

    func testNoLiveTimelineWhenBrowsingPreviousDay() {
        nav.timerHarness.tapReprendre(at: today)
        nav.tapStatsIcon()
        nav.tapJourTab()
        nav.tapPrevious()

        XCTAssertFalse(nav.calendar.isDate(nav.selectedDate, inSameDayAs: today))
        XCTAssertTrue(nav.displayTimeline(at: today.addingTimeInterval(2)).isEmpty)
    }

    func testNavigateBackToTodayRestoresLiveTimeline() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.tapStatsIcon()
        nav.tapJourTab()
        nav.tapPrevious()
        nav.tapAujourdhui(to: today)

        let displayed = nav.displayTimeline(at: today.addingTimeInterval(1))
        XCTAssertEqual(displayed.count, 1)
        XCTAssertEqual(displayed[0].kind, .focus)
        XCTAssertEqual(displayed[0].duration, 1, accuracy: 0.001)
    }

    func testDisplayTimelineMergePersistedAndLiveOnJour() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.timerHarness.tapPause(at: today.addingTimeInterval(3))
        nav.timerHarness.tapReprendre(at: today.addingTimeInterval(6))

        nav.timerHarness.tapPasser(at: today.addingTimeInterval(9))

        nav.tapStatsIcon()
        nav.tapJourTab()

        let runningAt = today.addingTimeInterval(11)
        let displayed = nav.displayTimeline(at: runningAt)

        XCTAssertEqual(displayed.count, 3)
        XCTAssertEqual(displayed[0].kind, .focus)
        XCTAssertEqual(displayed[0].duration, 3, accuracy: 0.001)
        XCTAssertEqual(displayed[1].kind, .focus)
        XCTAssertEqual(displayed[1].duration, 3, accuracy: 0.001)
        XCTAssertEqual(displayed[2].kind, .rest)
        XCTAssertEqual(displayed[2].duration, 2, accuracy: 0.001)
    }

    func testDisplayTimelineWallClockPauseGapOnJour() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.timerHarness.tapPause(at: today.addingTimeInterval(10))

        nav.tapStatsIcon()
        nav.tapJourTab()

        let pausedAt = today.addingTimeInterval(13)
        var displayed = nav.displayTimeline(at: pausedAt)
        XCTAssertEqual(displayed.count, 1)
        XCTAssertEqual(displayed[0].kind, .focus)
        XCTAssertEqual(displayed[0].duration, 10, accuracy: 0.001)
        XCTAssertEqual(displayed[0].endDate, today.addingTimeInterval(10))

        nav.timerHarness.tapReprendre(at: pausedAt)

        let runningAt = pausedAt.addingTimeInterval(15)
        displayed = nav.displayTimeline(at: runningAt)
        XCTAssertEqual(displayed.count, 2)
        XCTAssertEqual(displayed[0].kind, .focus)
        XCTAssertEqual(displayed[0].duration, 10, accuracy: 0.001)
        XCTAssertEqual(displayed[1].kind, .focus)
        XCTAssertEqual(displayed[1].duration, 15, accuracy: 0.001)
    }

    // MARK: - Week navigation

    func testPreviousWeekShowsNoTodaySessions() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.timerHarness.tickCompletion(at: today.addingTimeInterval(5))

        nav.tapStatsIcon()
        nav.tapSemaineTab()
        nav.tapPrevious()

        XCTAssertEqual(nav.weekSummary().totalFocusDuration, 0, accuracy: 0.001)
        XCTAssertEqual(nav.daySummary(at: today.addingTimeInterval(5)).focusCount, 0)
    }

    func testWeekColumnShowsFocusCountForToday() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.timerHarness.tickCompletion(at: today.addingTimeInterval(5))
        nav.timerHarness.tapPasser(at: today.addingTimeInterval(6)) // skip rest → focus auto-starts
        nav.timerHarness.tapPasser(at: today.addingTimeInterval(9))

        nav.tapStatsIcon()
        nav.tapSemaineTab()

        let todayEntry = try XCTUnwrap(nav.weekDayEntry(containing: today))
        XCTAssertEqual(todayEntry.focusCount, 2)
        XCTAssertEqual(todayEntry.restCount, 0)
        XCTAssertEqual(todayEntry.focusDuration, 8, accuracy: 0.001)
        XCTAssertEqual(nav.weekSummary().totalFocusDuration, 8, accuracy: 0.001)
    }

    // MARK: - Full focus + rest cycle

    func testAutoStartBreakRecordsBothInDayAndWeekViews() throws {
        timer.configuration.autoStartBreaks = true

        nav.timerHarness.tapReprendre(at: today)
        nav.timerHarness.tickCompletion(at: today.addingTimeInterval(5))
        nav.timerHarness.tickCompletion(at: today.addingTimeInterval(7))

        nav.tapStatsIcon()
        nav.tapJourTab()

        let afterRest = today.addingTimeInterval(7)
        let day = nav.daySummary(at: afterRest)
        XCTAssertEqual(day.focusCount, 1)
        XCTAssertEqual(day.restCount, 0) // 2 s calm < seuil compteur (3 s tests)
        XCTAssertEqual(day.focusDuration, 5, accuracy: 0.001)
        XCTAssertEqual(day.restDuration, 2, accuracy: 0.001)

        nav.tapSemaineTab()
        let todayEntry = try XCTUnwrap(nav.weekDayEntry(containing: today))
        XCTAssertEqual(todayEntry.focusCount, 1)
        XCTAssertEqual(todayEntry.restCount, 0)
    }

    // MARK: - Toolbar reset semantics

    func testTimerIconFromStatsDoesNotResetRunningSession() {
        nav.timerHarness.tapReprendre(at: today)
        nav.tapStatsIcon()
        nav.tapTimerIcon(at: today.addingTimeInterval(2))

        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.activeElapsed(at: today.addingTimeInterval(2)), 2, accuracy: 0.001)
        XCTAssertTrue(store.sessions.isEmpty)
    }

    func testTimerIconFromTimerResetsSession() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.timerHarness.tapPause(at: today.addingTimeInterval(3))
        nav.tapTimerIcon(at: today.addingTimeInterval(13))

        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.activeElapsed(at: today.addingTimeInterval(13)), 0, accuracy: 0.001)
        XCTAssertEqual(store.sessions.count, 1)
        let session = try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(session.duration, 3, accuracy: 0.001)
    }

    // MARK: - Black time across navigation

    func testPauseGapExcludedAfterNavigatingAcrossTabs() throws {
        nav.timerHarness.tapReprendre(at: today)
        nav.timerHarness.tapPause(at: today.addingTimeInterval(2))

        nav.tapStatsIcon()
        nav.tapSemaineTab()
        nav.tapJourTab()
        nav.tapTimerIcon(at: today.addingTimeInterval(20))

        nav.timerHarness.tapReprendre(at: today.addingTimeInterval(20))
        nav.timerHarness.tickCompletion(at: today.addingTimeInterval(23))

        XCTAssertEqual(store.sessions.count, 2)
        XCTAssertEqual(store.sessions[0].duration, 2, accuracy: 0.001)
        XCTAssertEqual(store.sessions[1].duration, 3, accuracy: 0.001)
        XCTAssertEqual(nav.daySummary(at: today.addingTimeInterval(23)).focusDuration, 5, accuracy: 0.001)
    }
}
