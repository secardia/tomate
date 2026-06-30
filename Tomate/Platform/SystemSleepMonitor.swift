import AppKit
import Foundation

private extension Notification.Name {
    static let screenIsLocked = Notification.Name("com.apple.screenIsLocked")
    static let screenIsUnlocked = Notification.Name("com.apple.screenIsUnlocked")
}

/// Observes system sleep, display sleep, and screen lock at app scope.
@MainActor
final class SystemSleepController {
    private let timer: PomodoroTimer
    private var workspaceObservers: [NSObjectProtocol] = []
    private var distributedObservers: [NSObjectProtocol] = []

    init(timer: PomodoroTimer) {
        self.timer = timer
        registerObservers()
    }

    deinit {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers {
            workspaceCenter.removeObserver(observer)
        }
        let distributedCenter = DistributedNotificationCenter.default()
        for observer in distributedObservers {
            distributedCenter.removeObserver(observer)
        }
    }

    private func registerObservers() {
        registerWorkspaceObservers()
        registerDistributedObservers()
    }

    private func registerWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter
        let suspendEvents: [(Notification.Name, AutomaticSuspendCause)] = [
            (NSWorkspace.willSleepNotification, .systemSleep),
            (NSWorkspace.screensDidSleepNotification, .displaySleep),
        ]
        let resumeEvents: [(Notification.Name, AutomaticSuspendCause)] = [
            (NSWorkspace.didWakeNotification, .systemSleep),
            (NSWorkspace.screensDidWakeNotification, .displaySleep),
        ]

        for (name, cause) in suspendEvents {
            workspaceObservers.append(
                center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.timer.handleAutomaticSuspend(cause, at: Date())
                    }
                }
            )
        }

        for (name, cause) in resumeEvents {
            workspaceObservers.append(
                center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.handleAutomaticResume(cause)
                    }
                }
            )
        }
    }

    private func registerDistributedObservers() {
        let center = DistributedNotificationCenter.default()

        distributedObservers.append(
            center.addObserver(forName: .screenIsLocked, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.timer.handleAutomaticSuspend(.screenLock, at: Date())
                }
            }
        )

        distributedObservers.append(
            center.addObserver(forName: .screenIsUnlocked, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.handleAutomaticResume(.screenLock)
                }
            }
        )
    }

    private func handleAutomaticResume(_ cause: AutomaticSuspendCause) {
        if timer.handleAutomaticResume(cause, at: Date()) {
            AppWindowController.activate()
        }
    }
}
