import CoreData
import Foundation

@objc(SessionEntity)
final class SessionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var type: String
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date

    var sessionType: SessionType {
        get { SessionType(rawValue: type) ?? .focus }
        set { type = newValue.rawValue }
    }

    func asRecord() -> SessionRecord {
        SessionRecord(id: id, type: sessionType, startDate: startDate, endDate: endDate)
    }

    static func insert(_ record: SessionRecord, into context: NSManagedObjectContext) {
        let entity = SessionEntity(context: context)
        entity.id = record.id
        entity.type = record.type.rawValue
        entity.startDate = record.startDate
        entity.endDate = record.endDate
    }
}
