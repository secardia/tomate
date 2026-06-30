import SwiftUI

struct TimerProgressBar: View {
    @Bindable var timer: PomodoroTimer
    let now: Date

    var body: some View {
        ProgressBarTrack(trackColor: timer.phase.accentMutedColor) { width in
            Rectangle()
                .fill(timer.phase.accentColor)
                .frame(width: width * timer.progress(at: now))
        }
    }
}

struct TimerBottomChrome: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        EdgeChrome {
            TimerProgressBar(
                timer: timer,
                now: timer.displayNow
            )
        }
    }
}
