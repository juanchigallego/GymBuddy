import CoreData

@objc(Routine)
public class Routine: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var day: String?
    @NSManaged public var targetMuscleGroups: NSArray?
    @NSManaged public var notes: String?
    @NSManaged public var blocks: NSSet?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isArchived: Bool
    
    public var blockID: UUID {
        id ?? UUID()
    }
} 