import SwiftUI

@main
struct TomateApp: App {
    @State private var store: SessionStore
    @State private var timer: PomodoroTimer
    private let sleepController: SystemSleepController

    init() {
        AppPreferences.register()
        let store = SessionStore()
        let configuration = TimerConfiguration.fromPreferences()
        let timer = PomodoroTimer(recording: store, configuration: configuration)
        _store = State(wrappedValue: store)
        _timer = State(wrappedValue: timer)
        sleepController = SystemSleepController(timer: timer)
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, timer: timer)
                .configureAppWindow()
        }
        .defaultSize(
            width: AppWindowMetrics.defaultSize.width,
            height: AppWindowMetrics.defaultSize.height
        )
        .windowResizability(.automatic)

        Settings {
            SettingsView(timer: timer)
        }
    }
}
