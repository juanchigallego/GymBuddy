import CoreData

@objc(ExerciseProgress)
public class ExerciseProgress: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var weight: Double
    @NSManaged public var reps: Int16
    @NSManaged public var notes: String?
    @NSManaged public var exerciseName: String?
    @NSManaged public var exercise: Exercise?
    @NSManaged public var completedExercise: CompletedExercise?
} 