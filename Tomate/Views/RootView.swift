import SwiftUI

struct RootView: View {
    @State private var navigation = StatsNavigationModel()

    let store: SessionStore
    @Bindable var timer: PomodoroTimer

    private var calendar: Calendar { StatsCalendar.french }

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
        .background {
            SystemSleepMonitor(timer: timer)
            AppTerminationMonitor(timer: timer)
            LiveDisplayDriver(timer: timer)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            switch navigation.screen {
            case .timer:
                TimerBottomChrome(timer: timer)
            case .stats where navigation.period == .day:
                DayTimelineBar(
                    persistedTimeline: dayTimelineForSelectedDate,
                    selectedDate: navigation.selectedDate,
                    timer: timer
                )
                .frame(maxWidth: .infinity)
            default:
                EmptyView()
            }
        }
        .onChange(of: navigation.selectedDate) { _, _ in
            syncSessionWindow()
        }
        .onChange(of: navigation.period) { _, _ in
            syncSessionWindow()
        }
        .onChange(of: navigation.screen) { _, screen in
            if screen == .stats {
                syncSessionWindow()
            }
        }
    }

    private func syncSessionWindow() {
        store.updateWindow(
            for: navigation.selectedDate,
            period: navigation.period,
            shiftDirection: navigation.consumeDateShiftDirection()
        )
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                if navigation.screen == .stats {
                    statsPeriodTabs
                }

                Spacer(minLength: 0)

                TopToolbar(
                    screen: navigation.screen,
                    onTimerTap: {
                        navigation.tapTimer { timer.reset() }
                    },
                    onStatsTap: {
                        navigation.tapStats()
                    }
                )
            }
            .padding(.horizontal, AppLayoutMetrics.topBarMargin)
            .frame(minHeight: AppLayoutMetrics.topBarContentHeight, alignment: .top)
        }
        .padding(.top, AppLayoutMetrics.topBarMargin)
        .background(AppColors.background)
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
                onPrevious: { navigation.shiftDate(by: -1) },
                onToday: { navigation.goToToday() },
                onNext: { navigation.shiftDate(by: 1) }
            )

            if navigation.period == .week {
                Text(DurationFormatter.clockDuration(weekFocusTotal(at: timer.displayNow)))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.focus)
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
                        action: { navigation.period = item }
                    ) {
                        Text(item.rawValue)
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
        let reference = timer.timelineDisplayDate(at: now)
        let live = timer.liveActiveDuration(at: reference, selectedDate: reference, calendar: calendar)
        return store.weekSummary(
            for: navigation.selectedDate,
            calendar: calendar,
            liveForDate: reference,
            liveFocusDuration: live.focus,
            liveRestDuration: live.rest
        ).totalFocusDuration
    }
}

#Preview {
    let store = SessionStore()
    let config = TimerConfiguration(
        focusDurationSeconds: 25 * 60,
        restDurationSeconds: 5 * 60,
        autoStartBreaks: true,
        minimumSessionCountSeconds: TimerConfiguration.defaultMinimumSessionCountSeconds
    )
    RootView(store: store, timer: PomodoroTimer(recording: store, configuration: config))
}
