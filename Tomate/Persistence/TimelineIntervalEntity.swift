import CoreData
import Foundation

@objc(TimelineIntervalEntity)
final class TimelineIntervalEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var kind: String
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date

    var intervalKind: TimelineIntervalKind {
        get { TimelineIntervalKind(rawValue: kind) ?? .focus }
        set { kind = newValue.rawValue }
    }

    func asInterval() -> TimelineInterval {
        TimelineInterval(id: id, kind: intervalKind, startDate: startDate, endDate: endDate)
    }

    static func insert(_ interval: TimelineInterval, into context: NSManagedObjectContext) {
        let entity = TimelineIntervalEntity(context: context)
        entity.id = interval.id
        entity.kind = interval.kind.rawValue
        entity.startDate = interval.startDate
        entity.endDate = interval.endDate
    }
}
