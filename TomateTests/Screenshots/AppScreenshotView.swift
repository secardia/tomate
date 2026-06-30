import SwiftUI
@testable import Tomate

/// Root layout for README screenshots — injectable navigation, no live system monitors.
struct AppScreenshotView: View {
    @Bindable var navigation: StatsNavigationModel
    @AppStorage(AppPreferences.languageKey) private var languageRaw = AppLanguage.systemDefault.rawValue
    @AppStorage(AppPreferences.firstWeekdayKey) private var firstWeekdayRaw = WeekStartDay.systemDefault.rawValue

    let store: SessionStore
    @Bindable var timer: PomodoroTimer

    private var calendar: Calendar { StatsCalendar.stats }

    var body: some View {
        Group {
            switch navigation.screen {
            case .timer:
                TimerView(timer: timer)
            case .stats:
                statsContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            switch navigation.screen {
            case .timer:
                TimerBottomChrome(timer: timer)
            case .stats where navigation.period == .day:
                DayTimelineChrome(
                    persistedTimeline: dayTimelineForSelectedDate,
                    selectedDate: navigation.selectedDate,
                    timer: timer
                )
                .frame(maxWidth: .infinity)
            default:
                EmptyView()
            }
        }
        .onAppear {
            syncSessionWindow()
        }
        .id("\(languageRaw)-\(firstWeekdayRaw)")
    }

    private func syncSessionWindow() {
        store.updateWindow(
            for: navigation.selectedDate,
            period: navigation.period,
            shiftDirection: navigation.consumeDateShiftDirection()
        )
    }

    private var topBar: some View {
        EdgeChrome(
            padding: EdgeInsets(
                top: AppLayoutMetrics.topBarMargin,
                leading: 0,
                bottom: 0,
                trailing: 0
            )
        ) {
            HStack {
                if navigation.screen == .stats {
                    statsPeriodTabs
                }

                Spacer(minLength: 0)

                TopToolbar(
                    screen: navigation.screen,
                    onTimerTap: {},
                    onStatsTap: {}
                )
            }
            .padding(.horizontal, AppLayoutMetrics.topBarMargin)
            .frame(minHeight: AppLayoutMetrics.topBarContentHeight, alignment: .top)
        }
    }

    @ViewBuilder
    private var statsContent: some View {
        VStack(spacing: 0) {
            statsHeader

            Spacer(minLength: 0)

            switch navigation.period {
            case .day:
                DayStatsView(store: store, timer: timer, selectedDate: $navigation.selectedDate)
            case .week:
                WeekStatsView(store: store, timer: timer, selectedDate: $navigation.selectedDate)
            }

            Spacer(minLength: 0)
        }
    }

    private var statsHeader: some View {
        VStack(spacing: 8) {
            StatsDateNavigator(
                title: navigation.statsNavigationTitle(),
                onPrevious: {},
                onToday: {},
                onNext: {}
            )

            if navigation.period == .week {
                Text(DurationFormatter.clockDuration(weekFocusTotal(at: timer.displayNow)))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SessionType.focus.accentColor)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, AppLayoutMetrics.contentMargin)
        .padding(.top, 16)
    }

    private var statsPeriodTabs: some View {
        SegmentedControlGroup {
            HStack(spacing: 2) {
                ForEach(StatsPeriod.allCases, id: \.self) { item in
                    SegmentedControlCell(
                        size: SegmentedControlMetrics.periodCell,
                        isActive: navigation.period == item,
                        action: {}
                    ) {
                        Text(item.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(navigation.period == item ? AppColors.textPrimary : AppColors.textSecondary)
                    }
                }
            }
        }
    }

    private var dayTimelineForSelectedDate: [TimelineInterval] {
        store.timeline(on: navigation.selectedDate, calendar: calendar)
    }

    private func weekFocusTotal(at now: Date) -> TimeInterval {
        let reference = StatsLiveSnapshot.referenceDate(timer: timer, at: now)
        let live = StatsLiveSnapshot.liveDurations(
            timer: timer,
            at: reference,
            selectedDate: reference,
            calendar: calendar
        )
        return store.weekSummary(
            for: navigation.selectedDate,
            calendar: calendar,
            liveForDate: reference,
            liveFocusDuration: live.focus,
            liveRestDuration: live.rest
        ).totalFocusDuration
    }
}
