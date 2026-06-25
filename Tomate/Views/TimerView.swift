import SwiftUI

enum TimerDisplay {
    static func seconds(from remaining: TimeInterval, total: Int) -> Int {
        guard remaining > 0 else { return 0 }
        return min(total, Int(ceil(remaining)))
    }
}

struct TimerView: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        GeometryReader { geometry in
            let upwardShift = geometry.size.height * AppLayoutMetrics.timerVerticalShiftRatio

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Text(timer.phase.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(timer.phase.accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(timer.phase.accentMutedColor)
                    .clipShape(Capsule())
                    .padding(.bottom, 12)

                TimerClockLabel(
                    remaining: timer.remainingTime(at: timer.displayNow),
                    total: timer.totalSeconds
                )
                .frame(height: 58)
                .padding(.bottom, 16)

                TimerControlButtons(timer: timer)

                Spacer(minLength: upwardShift)
            }
            .padding(.top, AppLayoutMetrics.timerContentTopPadding)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct TimerBottomChrome: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        TimerProgressBar(
            timer: timer,
            now: timer.displayNow
        )
        .frame(height: AppLayoutMetrics.progressBarHeight)
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
    }
}

private struct TimerControlButtons: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        VStack(spacing: 6) {
            Button {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    timer.togglePause(at: Date())
                }
            } label: {
                Text(timer.playPauseButtonLabel)
                    .frame(maxWidth: .infinity)
                    .timerButtonStyle()
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Button {
                    timer.reset(at: Date())
                } label: {
                    Text(AppStrings.Timer.reset)
                        .frame(maxWidth: .infinity)
                        .timerButtonStyle()
                }
                .buttonStyle(.plain)

                Button {
                    timer.skip(at: Date())
                } label: {
                    Text(AppStrings.Timer.skip)
                        .frame(maxWidth: .infinity)
                        .timerButtonStyle()
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 220, height: AppLayoutMetrics.timerControlsHeight, alignment: .top)
        .fixedSize(horizontal: true, vertical: true)
        .animation(.none, value: timer.isRunning)
    }
}

private struct TimerClockLabel: View {
    let remaining: TimeInterval
    let total: Int

    var body: some View {
        Text(formatTime(TimerDisplay.seconds(from: remaining, total: total)))
            .font(.system(size: 52, weight: .regular, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(AppColors.textPrimary)
            .contentTransition(.numericText())
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

private struct TimerProgressBar: View {
    @Bindable var timer: PomodoroTimer
    let now: Date

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(timer.phase.accentMutedColor)
                Rectangle()
                    .fill(timer.phase.accentColor)
                    .frame(width: geometry.size.width * timer.progress(at: now))
            }
        }
    }
}

private extension View {
    func timerButtonStyle() -> some View {
        font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.vertical, 7)
            .background(AppColors.controlFill)
            .clipShape(RoundedRectangle(cornerRadius: ControlCorners.standalone))
    }
}
