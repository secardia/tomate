import SwiftUI

struct SettingsView: View {
    @Bindable var timer: PomodoroTimer

    @State private var focusMinutes: Int
    @State private var restMinutes: Int
    @State private var autoStartBreaks: Bool

    init(timer: PomodoroTimer) {
        self.timer = timer
        _focusMinutes = State(initialValue: timer.configuration.focusDurationSeconds / 60)
        _restMinutes = State(initialValue: timer.configuration.restDurationSeconds / 60)
        _autoStartBreaks = State(initialValue: timer.configuration.autoStartBreaks)
    }

    var body: some View {
        Form {
            Section {
                Stepper(value: $focusMinutes, in: 1...120) {
                    Text("\(AppStrings.Settings.focusDuration): \(focusMinutes) min")
                }
                .onChange(of: focusMinutes) { _, newValue in
                    applyConfiguration(focusMinutes: newValue)
                }

                Stepper(value: $restMinutes, in: 1...60) {
                    Text("\(AppStrings.Settings.restDuration): \(restMinutes) min")
                }
                .onChange(of: restMinutes) { _, newValue in
                    applyConfiguration(restMinutes: newValue)
                }

                Toggle(AppStrings.Settings.autoStartBreaks, isOn: $autoStartBreaks)
                    .onChange(of: autoStartBreaks) { _, newValue in
                        applyConfiguration(autoStartBreaks: newValue)
                    }
            } footer: {
                Text(AppStrings.Settings.durationHint)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 360, minHeight: 220)
    }

    private func applyConfiguration(
        focusMinutes: Int? = nil,
        restMinutes: Int? = nil,
        autoStartBreaks: Bool? = nil
    ) {
        let focus = focusMinutes ?? self.focusMinutes
        let rest = restMinutes ?? self.restMinutes
        let autoStart = autoStartBreaks ?? self.autoStartBreaks

        AppPreferences.focusDurationSeconds = focus * 60
        AppPreferences.restDurationSeconds = rest * 60
        AppPreferences.autoStartBreaks = autoStart

        timer.applyConfiguration(
            TimerConfiguration(
                focusDurationSeconds: focus * 60,
                restDurationSeconds: rest * 60,
                autoStartBreaks: autoStart,
                minimumSessionCountSeconds: timer.configuration.minimumSessionCountSeconds
            )
        )
    }
}
