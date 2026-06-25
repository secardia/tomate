import AppKit
import SwiftUI

/// Pauses the timer when the Mac sleeps and resumes it on wake if it was running.
struct SystemSleepMonitor: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        Color.clear
            .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.willSleepNotification)) { _ in
                timer.handleSystemWillSleep(at: Date())
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                timer.handleSystemDidWake(at: Date())
            }
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}
