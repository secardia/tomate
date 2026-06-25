import Foundation

enum TimelineIntervalKind: String, Codable {
    case focus
    case rest
}

struct TimelineInterval: Codable, Identifiable, Equatable {
    let id: UUID
    let kind: TimelineIntervalKind
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}
