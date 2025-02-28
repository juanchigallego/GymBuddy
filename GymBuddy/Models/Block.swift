import CoreData

@objc(Block)
public class Block: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var sets: Int16
    @NSManaged public var completedSets: Int16
    @NSManaged public var restSeconds: Int16
    @NSManaged public var exercises: NSSet?
    @NSManaged public var routine: GymBuddy.Routine?
} 
