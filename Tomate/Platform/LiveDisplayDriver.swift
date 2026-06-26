import SwiftUI

/// Logical poll while the chrono runs; `PomodoroTimer.poll` only publishes UI when the displayed second changes.
struct LiveDisplayDriver: View {
    @Bindable var timer: PomodoroTimer
    var onPhaseChange: () -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .task(id: timer.isRunning) {
                guard timer.isRunning else { return }
                while !Task.isCancelled && timer.isRunning {
                    timer.poll(at: Date(), onPhaseChange: onPhaseChange)
                    try? await Task.sleep(for: .seconds(TimerRefreshMetrics.pollInterval))
                }
            }
    }
}
