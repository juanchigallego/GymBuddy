import CoreData

@objc(Exercise)
public class Exercise: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var repsPerSet: Int16
    @NSManaged public var weight: Double
    @NSManaged public var notes: String?
    @NSManaged public var targetMuscles: NSArray?
    @NSManaged public var block: GymBuddy.Block?
} 