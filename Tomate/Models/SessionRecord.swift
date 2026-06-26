import Foundation

enum SessionType: String, Codable {
    case focus
    case rest
}

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let type: SessionType
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}

struct DaySummary {
    let focusCount: Int
    let restCount: Int
    let focusDuration: TimeInterval
    let restDuration: TimeInterval
}

struct DayWeekEntry {
    let date: Date
    let focusCount: Int
    let restCount: Int
    let focusDuration: TimeInterval
}

struct WeekSummary {
    let days: [DayWeekEntry]
    let totalFocusDuration: TimeInterval
}

enum DurationFormatter {
    /// Compact stats label (e.g. `5m`, `1.5h`) — uses raw interval.
    static func format(_ interval: TimeInterval) -> String {
        let hours = interval / 3600
        if hours < 1 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        }
        return String(format: "%.1fh", hours)
    }

    /// Stats clock display — rounds up to the next minute before formatting as `HH:MM`.
    static func clockDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(ceil(interval / 60)))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

enum TimeFormatter {
    static func hourMinute(_ date: Date) -> String {
        switch AppPreferences.language {
        case .english:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        case .french:
            let calendar = StatsCalendar.stats
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            return "\(hour)h\(String(format: "%02d", minute))"
        }
    }
}
