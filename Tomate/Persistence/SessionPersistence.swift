import Foundation

protocol SessionPersistence {
    func fetchSessions(from start: Date, to end: Date) throws -> [SessionRecord]
    func insert(_ record: SessionRecord) throws
    func fetchTimelineIntervals(from start: Date, to end: Date) throws -> [TimelineInterval]
    func insertTimeline(_ interval: TimelineInterval) throws
    func purgeLegacyIdleTimelineIntervals() throws
}
