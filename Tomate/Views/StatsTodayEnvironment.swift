import SwiftUI

private enum StatsTodayKey: EnvironmentKey {
    static var defaultValue: Date { Date() }
}

extension EnvironmentValues {
    var statsToday: Date {
        get { self[StatsTodayKey.self] }
        set { self[StatsTodayKey.self] = newValue }
    }
}
