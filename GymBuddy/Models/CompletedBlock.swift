import CoreData

@objc(CompletedBlock)
public class CompletedBlock: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var blockName: String?
    @NSManaged public var completionTime: Double
    @NSManaged public var isSkipped: Bool
    @NSManaged public var sets: Int16
    @NSManaged public var exercises: NSSet?
    @NSManaged public var workout: CompletedWorkout?
    
    public var exerciseArray: [CompletedExercise] {
        let set = exercises as? Set<CompletedExercise> ?? []
        return set.sorted { $0.exerciseName ?? "" < $1.exerciseName ?? "" }
    }
    
    public var formattedCompletionTime: String {
        let minutes = Int(completionTime) / 60
        let seconds = Int(completionTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 