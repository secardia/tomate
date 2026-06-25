import SwiftUI

@main
struct TomateApp: App {
    @State private var store: SessionStore
    @State private var timer: PomodoroTimer

    init() {
        AppPreferences.register()
        let store = SessionStore()
        let configuration = TimerConfiguration.fromPreferences()
        _store = State(wrappedValue: store)
        _timer = State(wrappedValue: PomodoroTimer(recording: store, configuration: configuration))
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
