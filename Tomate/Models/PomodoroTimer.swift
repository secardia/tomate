import Foundation
import Observation

enum PomodoroPhase {
    case focus
    case rest

    var sessionType: SessionType {
        switch self {
        case .focus: .focus
        case .rest: .rest
        }
    }

    var timelineKind: TimelineIntervalKind {
        switch self {
        case .focus: .focus
        case .rest: .rest
        }
    }

    var label: String {
        switch self {
        case .focus: AppStrings.Phase.focus
        case .rest: AppStrings.Phase.rest
        }
    }
}

@Observable
final class PomodoroTimer {
    private(set) var phase: PomodoroPhase = .focus
    private(set) var isRunning = false
    var configuration: TimerConfiguration

    private let recording: any SessionRecording
    private var phaseEndDate: Date?
    private var pausedRemaining: TimeInterval?
    /// Wall-clock instant when the timer was paused; anchors the frozen live segment.
    private var pausedAt: Date?

    private var pendingTimeline: [TimelineInterval] = []
    private var activeSegmentStart: Date?
    /// True when the current pause was triggered by system sleep (auto-resume on wake).
    private var pausedForSystemSleep = false

    /// Anchor for live UI; advances only when the displayed countdown second changes while running.
    private(set) var displayNow: Date = Date()
    private var lastPublishedDisplaySecond: Int?

    var totalSeconds: Int { configuration.durationSeconds(for: phase) }

    /// True when the timer was paused mid-phase (as opposed to idle at rest or after reset).
    var isPaused: Bool { pausedAt != nil }

    var playPauseButtonLabel: String {
        if isRunning { return AppStrings.Timer.pause }
        return isPaused ? AppStrings.Timer.resume : AppStrings.Timer.start
    }

    init(recording: any SessionRecording, configuration: TimerConfiguration) {
        self.recording = recording
        self.configuration = configuration
        pausedRemaining = TimeInterval(configuration.focusDurationSeconds)
    }

    /// Date used to render the day timeline; frozen while the timer is paused.
    func timelineDisplayDate(at now: Date) -> Date {
        isPaused ? (pausedAt ?? now) : now
    }

    /// Active seconds elapsed in the current phase (running time only — pauses and reset idle are excluded).
    func activeElapsed(at now: Date) -> TimeInterval {
        max(0, Double(totalSeconds) - remainingTime(at: now))
    }

    /// End of the in-progress segment on the day timeline; nil when there is no active progress.
    func liveSegmentEnd(at now: Date) -> Date? {
        guard activeElapsed(at: now) > 0 else { return nil }
        if isRunning { return now }
        return pausedAt
    }

    /// Wall-clock timeline for the current phase (persisted pending + open segments).
    func timelineIntervals(at now: Date) -> [TimelineInterval] {
        let reference = timelineDisplayDate(at: now)
        var result = pendingTimeline

        if let start = activeSegmentStart, reference > start {
            let end: Date
            if isPaused, let pauseStart = pausedAt {
                end = pauseStart
            } else if isRunning {
                end = reference
            } else {
                end = reference
            }
            if end > start {
                result.append(TimelineInterval(
                    id: UUID(),
                    kind: phase.timelineKind,
                    startDate: start,
                    endDate: end
                ))
            }
        }

        return result.sorted { $0.startDate < $1.startDate }
    }

    func remainingTime(at now: Date) -> TimeInterval {
        if isRunning, let end = phaseEndDate {
            return max(0, end.timeIntervalSince(now))
        }
        return pausedRemaining ?? 0
    }

    func progress(at now: Date) -> Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - remainingTime(at: now) / Double(totalSeconds)
    }

    func checkCompletion(at now: Date) {
        guard isRunning, remainingTime(at: now) <= 0 else { return }
        let segments = buildSegmentsForFinalization(at: now)
        persistTimeline(segments)
        completeSession(from: segments)
        switchPhase(autoStart: true, startNextPhase: false, at: now)
    }

    /// Poll entry point: completion check every call; `displayNow` only when the shown second changes.
    func poll(at now: Date, onPhaseChange: () -> Void) {
        guard isRunning else { return }
        let phaseBefore = phase
        checkCompletion(at: now)
        if phase != phaseBefore {
            onPhaseChange()
            publishDisplayNow(at: now, force: true)
            return
        }
        publishDisplayNowIfSecondChanged(at: now)
    }

    private func publishDisplayNowIfSecondChanged(at now: Date) {
        let second = TimerDisplay.seconds(from: remainingTime(at: now), total: totalSeconds)
        guard second != lastPublishedDisplaySecond else { return }
        lastPublishedDisplaySecond = second
        displayNow = now
    }

    private func publishDisplayNow(at now: Date, force: Bool) {
        let second = TimerDisplay.seconds(from: remainingTime(at: now), total: totalSeconds)
        if force || second != lastPublishedDisplaySecond {
            lastPublishedDisplaySecond = second
            displayNow = now
        }
    }

    private func freezeDisplayNow(at now: Date) {
        lastPublishedDisplaySecond = TimerDisplay.seconds(from: remainingTime(at: now), total: totalSeconds)
        displayNow = timelineDisplayDate(at: now)
    }

    private func resetDisplayTrackingForNewRun(at now: Date) {
        lastPublishedDisplaySecond = nil
        publishDisplayNow(at: now, force: true)
    }

    /// Wall-clock active time in the open segment (not yet flushed to the store).
    func liveActiveDuration(
        at now: Date,
        selectedDate: Date,
        calendar: Calendar = StatsCalendar.stats
    ) -> (focus: TimeInterval, rest: TimeInterval) {
        guard calendar.isDate(selectedDate, inSameDayAs: now),
              let start = activeSegmentStart else { return (0, 0) }
        let end: Date
        if isPaused, let pauseStart = pausedAt {
            end = pauseStart
        } else if isRunning {
            end = now
        } else {
            end = now
        }
        guard let duration = Self.durationClippedToDay(
            from: start,
            to: end,
            on: selectedDate,
            calendar: calendar
        ) else { return (0, 0) }
        switch phase {
        case .focus: return (duration, 0)
        case .rest: return (0, duration)
        }
    }

    /// Reconcile countdown state after focus/rest durations change in Settings.
    func applyConfiguration(_ configuration: TimerConfiguration, at now: Date = Date()) {
        let oldTotal = TimeInterval(self.configuration.durationSeconds(for: phase))
        let remaining = remainingTime(at: now)
        let elapsed = max(0, oldTotal - remaining)

        self.configuration = configuration
        let newTotal = TimeInterval(configuration.durationSeconds(for: phase))
        let newRemaining = max(0, newTotal - elapsed)

        if isRunning {
            if newRemaining <= 0 {
                checkCompletion(at: now)
                return
            }
            phaseEndDate = now.addingTimeInterval(newRemaining)
            pausedRemaining = nil
            resetDisplayTrackingForNewRun(at: now)
        } else if isPaused {
            pausedRemaining = newRemaining
            freezeDisplayNow(at: now)
        } else {
            pausedRemaining = newTotal
            freezeDisplayNow(at: now)
        }
    }

    private static func durationClippedToDay(
        from start: Date,
        to end: Date,
        on date: Date,
        calendar: Calendar
    ) -> TimeInterval? {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
        let clippedStart = max(start, dayStart)
        let clippedEnd = min(end, dayEnd)
        guard clippedEnd > clippedStart else { return nil }
        return clippedEnd.timeIntervalSince(clippedStart)
    }

    func togglePause(at now: Date) {
        if isRunning {
            flushActiveSegmentToStore(at: now)
            pausedRemaining = phaseEndDate.map { max(0, $0.timeIntervalSince(now)) }
            phaseEndDate = nil
            pausedAt = now
            isRunning = false
            freezeDisplayNow(at: now)
        } else {
            let remaining = pausedRemaining ?? TimeInterval(configuration.durationSeconds(for: phase))
            phaseEndDate = now.addingTimeInterval(remaining)
            pausedRemaining = nil
            pausedAt = nil
            activeSegmentStart = now
            isRunning = true
            resetDisplayTrackingForNewRun(at: now)
        }
    }

    func reset(at now: Date = Date()) {
        recordEndOfPhase(at: now)
        isRunning = false
        pausedRemaining = TimeInterval(configuration.durationSeconds(for: phase))
        phaseEndDate = nil
        pausedAt = nil
        clearTimelineTracking()
        freezeDisplayNow(at: now)
    }

    func skip(at now: Date) {
        recordEndOfPhase(at: now)
        switchPhase(autoStart: true, startNextPhase: true, at: now)
    }

    func handleSystemWillSleep(at now: Date) {
        guard isRunning else { return }
        togglePause(at: now)
        pausedForSystemSleep = true
    }

    func handleSystemDidWake(at now: Date) {
        guard pausedForSystemSleep else { return }
        pausedForSystemSleep = false
        guard isPaused else { return }
        togglePause(at: now)
    }

    // MARK: - Recording
    //
    // Product rule:
    // · Start / Resume / Skip (next phase) → starts the timer (`activeSegmentStart`).
    // · Pause / Skip (end of phase) / Reset / timer completion → flush to DB at click time
    //   (startDate…endDate interval of the current focus or break segment).

    private func recordEndOfPhase(at now: Date) {
        let segments = buildSegmentsForFinalization(at: now)
        let phaseKind = phase.timelineKind
        let newActive = activeDuration(in: segments, phaseKind: phaseKind)
        guard newActive > 0 || !segments.isEmpty else {
            discardTimelineWithoutPersisting()
            return
        }
        persistTimeline(segments)
        if newActive > 0 {
            completeSession(from: segments)
        }
    }

    private func buildSegmentsForFinalization(at now: Date) -> [TimelineInterval] {
        var segments = pendingTimeline
        if isRunning {
            if let start = activeSegmentStart, now > start {
                segments.append(TimelineInterval(
                    id: UUID(),
                    kind: phase.timelineKind,
                    startDate: start,
                    endDate: now
                ))
            }
        } else if isPaused, let pauseStart = pausedAt,
                  let start = activeSegmentStart, pauseStart > start {
            segments.append(TimelineInterval(
                id: UUID(),
                kind: phase.timelineKind,
                startDate: start,
                endDate: pauseStart
            ))
        }
        return segments.sorted { $0.startDate < $1.startDate }
    }

    private func activeDuration(in segments: [TimelineInterval], phaseKind: TimelineIntervalKind) -> TimeInterval {
        segments.filter { $0.kind == phaseKind }.reduce(0) { $0 + $1.duration }
    }

    private func flushActiveSegmentToStore(at end: Date) {
        guard let start = activeSegmentStart, end > start else { return }
        let interval = TimelineInterval(
            id: UUID(),
            kind: phase.timelineKind,
            startDate: start,
            endDate: end
        )
        recording.recordTimeline(interval)
        recording.record(type: phase.sessionType, start: start, end: end)
        activeSegmentStart = nil
    }

    private func persistTimeline(_ segments: [TimelineInterval]) {
        for interval in segments {
            recording.recordTimeline(interval)
        }
    }

    private func discardTimelineWithoutPersisting() {
        pendingTimeline = []
    }

    private func clearTimelineTracking() {
        pendingTimeline = []
        activeSegmentStart = nil
    }

    private func completeSession(from segments: [TimelineInterval]) {
        let phaseKind = phase.timelineKind
        for interval in segments where interval.kind == phaseKind {
            guard interval.duration > 0 else { continue }
            recording.record(type: phase.sessionType, start: interval.startDate, end: interval.endDate)
        }
    }

    private func switchPhase(autoStart: Bool, startNextPhase: Bool, at now: Date) {
        let endingFocus = phase == .focus
        phase = endingFocus ? .rest : .focus
        let duration = TimeInterval(configuration.durationSeconds(for: phase))
        pausedAt = nil
        clearTimelineTracking()
        let shouldRun = autoStart && (startNextPhase || !endingFocus || configuration.autoStartBreaks)
        isRunning = shouldRun
        pausedRemaining = shouldRun ? nil : duration
        phaseEndDate = shouldRun ? now.addingTimeInterval(duration) : nil
        activeSegmentStart = shouldRun ? now : nil
        if shouldRun {
            resetDisplayTrackingForNewRun(at: now)
        } else {
            freezeDisplayNow(at: now)
        }
    }
}
