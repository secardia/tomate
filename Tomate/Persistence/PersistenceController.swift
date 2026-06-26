import CoreData
import Foundation

extension PersistenceController: SessionPersistence {}

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Tomate", managedObjectModel: Self.makeModel())

        let storeDescription = NSPersistentStoreDescription()
        if inMemory {
            storeDescription.type = NSInMemoryStoreType
        } else {
            storeDescription.url = Self.storeURL
            storeDescription.type = NSSQLiteStoreType
        }
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Échec du chargement Core Data : \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    static func inMemory() -> PersistenceController {
        PersistenceController(inMemory: true)
    }

    static var storeURL: URL {
        let directory = applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("Tomate.sqlite")
    }

    static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let subdirectory = Bundle.main.bundleIdentifier ?? "Tomate"
        return base.appendingPathComponent(subdirectory, isDirectory: true)
    }

    func fetchSessions(from start: Date, to end: Date) throws -> [SessionRecord] {
        let request = NSFetchRequest<SessionEntity>(entityName: "Session")
        request.predicate = NSPredicate(format: "startDate >= %@ AND startDate < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        return try viewContext.fetch(request).map { $0.asRecord() }
    }

    func insert(_ record: SessionRecord) throws {
        SessionEntity.insert(record, into: viewContext)
        try viewContext.save()
    }

    func fetchTimelineIntervals(from start: Date, to end: Date) throws -> [TimelineInterval] {
        let request = NSFetchRequest<TimelineIntervalEntity>(entityName: "TimelineInterval")
        request.predicate = NSPredicate(format: "startDate >= %@ AND startDate < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        return try viewContext.fetch(request).map { $0.asInterval() }
    }

    func insertTimeline(_ interval: TimelineInterval) throws {
        TimelineIntervalEntity.insert(interval, into: viewContext)
        try viewContext.save()
    }

    func purgeLegacyIdleTimelineIntervals() throws {
        let request = NSFetchRequest<TimelineIntervalEntity>(entityName: "TimelineInterval")
        request.predicate = NSPredicate(format: "kind == %@", "idle")
        let entities = try viewContext.fetch(request)
        for entity in entities {
            viewContext.delete(entity)
        }
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "Session"
        sessionEntity.managedObjectClassName = NSStringFromClass(SessionEntity.self)

        let timelineEntity = NSEntityDescription()
        timelineEntity.name = "TimelineInterval"
        timelineEntity.managedObjectClassName = NSStringFromClass(TimelineIntervalEntity.self)

        func uuidAttr() -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = "id"
            attr.attributeType = .UUIDAttributeType
            attr.isOptional = false
            return attr
        }

        func stringAttr(name: String) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = .stringAttributeType
            attr.isOptional = false
            return attr
        }

        func dateAttr(name: String) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = .dateAttributeType
            attr.isOptional = false
            return attr
        }

        sessionEntity.properties = [
            uuidAttr(),
            stringAttr(name: "type"),
            dateAttr(name: "startDate"),
            dateAttr(name: "endDate"),
        ]

        timelineEntity.properties = [
            uuidAttr(),
            stringAttr(name: "kind"),
            dateAttr(name: "startDate"),
            dateAttr(name: "endDate"),
        ]

        model.entities = [sessionEntity, timelineEntity]
        return model
    }
}
