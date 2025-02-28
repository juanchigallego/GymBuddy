import CoreData

@objc(CompletedExercise)
public class CompletedExercise: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var exerciseName: String?
    @NSManaged public var repsPerSet: Int16
    @NSManaged public var weight: Double
    @NSManaged public var notes: String?
    @NSManaged public var block: CompletedBlock?
} 