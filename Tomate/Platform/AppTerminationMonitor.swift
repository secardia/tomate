import AppKit
import SwiftUI

/// Records in-progress work and resets the timer when the app quits (Cmd+Q, Quit, etc.).
struct AppTerminationMonitor: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        Color.clear
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                timer.reset(at: Date())
            }
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}
