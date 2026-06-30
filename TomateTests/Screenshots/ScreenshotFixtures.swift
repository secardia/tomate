import Foundation
@testable import Tomate

/// Deterministic data for README screenshots (run with `TZ=Europe/Paris`).
/// Week of 22 June 2026: day stats on Thu 25 (full) and Fri 26 (live morning).
enum ScreenshotFixtures {
    static let timeZone = TimeZone(identifier: "Europe/Paris")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// Monday, 22 June 2026 — first day of the screenshot week.
    static let weekMonday: Date = {
        calendar.date(
            from: DateComponents(
                timeZone: timeZone,
                year: 2026,
                month: 6,
                day: 22,
                hour: 12
            )
        )!
    }()

    /// Thursday, 25 June 2026 — full-day stats screenshot.
    static let thursdayDay: Date = {
        calendar.date(byAdding: .day, value: 3, to: weekMonday)!
    }()

    /// Friday, 26 June 2026 — live morning stats + week "today".
    static let fridayDay: Date = {
        calendar.date(byAdding: .day, value: 4, to: weekMonday)!
    }()

    static let weekReferenceToday: Date = fridayDay

    static let screenshotConfiguration = TimerConfiguration(
        focusDurationSeconds: 25 * 60,
        restDurationSeconds: 5 * 60,
        autoStartBreaks: true,
        minimumSessionCountSeconds: TimerConfiguration.defaultMinimumSessionCountSeconds
    )

    static func registerPreferences() {
        TestPreferences.register()
        AppPreferences.focusDurationSeconds = screenshotConfiguration.focusDurationSeconds
        AppPreferences.restDurationSeconds = screenshotConfiguration.restDurationSeconds
        AppPreferences.autoStartBreaks = screenshotConfiguration.autoStartBreaks
    }

    static func makeStore() -> SessionStore {
        SessionStore(persistence: PersistenceController.inMemory(), calendar: StatsCalendar.stats)
    }

    static func makeIdleTimer(store: SessionStore) -> PomodoroTimer {
        PomodoroTimer(recording: store, configuration: screenshotConfiguration)
    }

    // MARK: - Timer running (18:32 remaining on a 25 min focus)

    static func makeTimerRunningScene() -> (store: SessionStore, timer: PomodoroTimer, navigation: StatsNavigationModel) {
        let store = makeStore()
        let timer = makeIdleTimer(store: store)
        let harness = TimerTestHarness(timer: timer)
        let start = time(on: fridayDay, hour: 14, minute: 7)
        harness.tapStartOrResume(at: start)
        harness.tickLiveDisplay(at: start.addingTimeInterval(6 * 60 + 28))
        let navigation = StatsNavigationModel(selectedDate: fridayDay)
        return (store, timer, navigation)
    }

    // MARK: - Day stats (Thu): 9:09–18:00, lunch ~11:57–13:39

    static func makeStatsDayScene() -> (store: SessionStore, timer: PomodoroTimer, navigation: StatsNavigationModel) {
        let store = makeStore()
        var nextID: UInt8 = 1
        seedSchedule(into: store, on: thursdayDay, blocks: thursdayDayBlocks, nextID: &nextID)
        let timer = makeIdleTimer(store: store)
        let navigation = statsDayNavigation(on: thursdayDay)
        store.updateWindow(for: thursdayDay, period: .day)
        return (store, timer, navigation)
    }

    // MARK: - Day stats (Fri): 9:09–11:57, live focus before lunch

    static func makeStatsDayLiveScene() -> (store: SessionStore, timer: PomodoroTimer, navigation: StatsNavigationModel) {
        let store = makeStore()
        var nextID: UInt8 = 1
        seedSchedule(into: store, on: fridayDay, blocks: fridayMorningBlocks, nextID: &nextID)

        let timer = makeIdleTimer(store: store)
        let harness = TimerTestHarness(timer: timer)
        let focusStart = time(on: fridayDay, hour: 11, minute: 50)
        let now = time(on: fridayDay, hour: 11, minute: 57)
        harness.tapStartOrResume(at: focusStart)
        harness.tickLiveDisplay(at: now)

        let navigation = statsDayNavigation(on: fridayDay)
        store.updateWindow(for: fridayDay, period: .day)
        return (store, timer, navigation)
    }

    // MARK: - Week stats (Mon–Fri, week of 22 June)

    static func makeStatsWeekScene() -> (store: SessionStore, timer: PomodoroTimer, navigation: StatsNavigationModel) {
        let store = makeStore()
        var nextID: UInt8 = 1
        seedSchedule(into: store, on: dayOffset(0), blocks: weekMondayBlocks, nextID: &nextID)
        seedSchedule(into: store, on: dayOffset(1), blocks: weekTuesdayBlocks, nextID: &nextID)
        seedSchedule(into: store, on: dayOffset(2), blocks: weekWednesdayBlocks, nextID: &nextID)
        seedSchedule(into: store, on: thursdayDay, blocks: thursdayDayBlocks, nextID: &nextID)
        seedSchedule(into: store, on: fridayDay, blocks: fridayMorningBlocks, nextID: &nextID)

        let timer = makeIdleTimer(store: store)
        let navigation = StatsNavigationModel(selectedDate: weekReferenceToday)
        navigation.screen = .stats
        navigation.period = .week
        store.updateWindow(for: weekReferenceToday, period: .week)
        return (store, timer, navigation)
    }

    // MARK: - Shared day schedules (also used in week Thu / Fri columns)

    /// Full Thursday — prod-derived, ends 18:00.
    private static let thursdayDayBlocks: [BlockSpec] = [
        BlockSpec(hour: 9, minute: 9, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 9, minute: 34, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 9, minute: 59, durationMinutes: 8, kind: .rest),
        BlockSpec(hour: 10, minute: 7, durationMinutes: 22, kind: .focus),
        BlockSpec(hour: 10, minute: 30, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 10, minute: 55, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 20, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 11, minute: 25, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 50, durationMinutes: 7, kind: .focus),
        BlockSpec(hour: 13, minute: 39, durationMinutes: 18, kind: .focus),
        BlockSpec(hour: 13, minute: 57, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 14, minute: 22, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 14, minute: 47, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 15, minute: 12, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 15, minute: 37, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 16, minute: 2, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 16, minute: 27, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 16, minute: 32, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 16, minute: 57, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 17, minute: 22, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 17, minute: 35, durationMinutes: 25, kind: .focus),
    ]

    /// Friday morning — same blocks as day-live before the in-progress session.
    private static let fridayMorningBlocks: [BlockSpec] = [
        BlockSpec(hour: 9, minute: 9, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 9, minute: 34, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 9, minute: 59, durationMinutes: 8, kind: .rest),
        BlockSpec(hour: 10, minute: 7, durationMinutes: 22, kind: .focus),
        BlockSpec(hour: 10, minute: 30, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 10, minute: 55, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 20, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 11, minute: 25, durationMinutes: 25, kind: .focus),
    ]

    // MARK: - Mon–Wed week schedules (8–17 sessions, breaks ≈ 50–70 % of sessions)

    /// 15 sessions · 8 breaks (53 %)
    private static let weekMondayBlocks: [BlockSpec] = [
        BlockSpec(hour: 9, minute: 9, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 9, minute: 34, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 9, minute: 41, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 10, minute: 6, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 10, minute: 13, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 10, minute: 38, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 10, minute: 45, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 10, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 35, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 11, minute: 42, durationMinutes: 15, kind: .focus),
        BlockSpec(hour: 13, minute: 39, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 14, minute: 4, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 14, minute: 29, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 14, minute: 54, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 15, minute: 1, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 15, minute: 26, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 15, minute: 51, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 15, minute: 58, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 16, minute: 23, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 16, minute: 48, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 16, minute: 55, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 17, minute: 20, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 17, minute: 27, durationMinutes: 25, kind: .focus),
    ]

    /// 10 sessions · 6 breaks (60 %)
    private static let weekTuesdayBlocks: [BlockSpec] = [
        BlockSpec(hour: 9, minute: 33, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 9, minute: 58, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 10, minute: 5, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 10, minute: 30, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 10, minute: 37, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 2, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 11, minute: 9, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 34, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 13, minute: 18, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 13, minute: 43, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 13, minute: 50, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 14, minute: 15, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 14, minute: 40, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 14, minute: 47, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 15, minute: 12, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 15, minute: 19, durationMinutes: 25, kind: .focus),
    ]

    /// 12 sessions · 7 breaks (58 %)
    private static let weekWednesdayBlocks: [BlockSpec] = [
        BlockSpec(hour: 9, minute: 19, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 9, minute: 44, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 9, minute: 51, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 10, minute: 16, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 10, minute: 23, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 10, minute: 48, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 13, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 11, minute: 20, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 11, minute: 45, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 11, minute: 52, durationMinutes: 18, kind: .focus),
        BlockSpec(hour: 14, minute: 28, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 14, minute: 53, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 15, minute: 18, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 15, minute: 25, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 15, minute: 50, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 16, minute: 15, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 16, minute: 22, durationMinutes: 25, kind: .focus),
        BlockSpec(hour: 16, minute: 47, durationMinutes: 5, kind: .rest),
        BlockSpec(hour: 16, minute: 54, durationMinutes: 25, kind: .focus),
    ]

    // MARK: - Seeding

    private struct BlockSpec {
        let hour: Int
        let minute: Int
        let durationMinutes: Int
        let kind: SessionType
    }

    private static func seedSchedule(
        into store: SessionStore,
        on day: Date,
        blocks: [BlockSpec],
        nextID: inout UInt8
    ) {
        for block in blocks {
            let start = time(on: day, hour: block.hour, minute: block.minute)
            let end = start.addingTimeInterval(TimeInterval(block.durationMinutes * 60))
            store.record(type: block.kind, start: start, end: end)
            let timelineKind: TimelineIntervalKind = block.kind == .focus ? .focus : .rest
            store.recordTimeline(
                TimelineInterval(id: id(nextID), kind: timelineKind, startDate: start, endDate: end)
            )
            nextID += 1
        }
    }

    private static func statsDayNavigation(on day: Date) -> StatsNavigationModel {
        let navigation = StatsNavigationModel(selectedDate: day)
        navigation.screen = .stats
        navigation.period = .day
        return navigation
    }

    private static func time(on day: Date, hour: Int, minute: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = timeZone
        return calendar.date(from: components)!
    }

    private static func dayOffset(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: weekMonday)!
    }

    private static func id(_ byte: UInt8) -> UUID {
        UUID(uuid: (
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, byte
        ))
    }
}
